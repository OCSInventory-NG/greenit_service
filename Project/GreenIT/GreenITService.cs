using GreenIT.LibreHardwareMonitor;
using System.ComponentModel;
using System.Globalization;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace GreenIT.Service
{
    public class GreenITService
    {
        private bool _allEngineState = false;
        private bool _serviceEngine = false;
        private bool _saveEngine = false;
        private bool _LibreHardwareMonitorEngine = false;
        private bool _stopEngineSignal = false;

        private readonly Mutex _mutex;
        private readonly BackgroundWorker _service;
        private readonly BackgroundWorker _save;
        private readonly BackgroundWorker _LibreHardwareMonitor;

        private readonly string _folderPath = @"C:\ProgramData\GreenIT";
        private readonly string _dataFilePath = @"C:\ProgramData\GreenIT\data.json";
        private readonly string _dataSavePath = @"C:\ProgramData\GreenIT\data.json.bak";
        private readonly string _configPath = @"config.json";

        private string[]? _reader;

        private JsonObject _config;

        private long _timestamp;

        public GreenITService()
        {
            _config = new JsonObject();

            _mutex = new Mutex();

            _service = new BackgroundWorker
            {
                WorkerSupportsCancellation = true
            };
            _service.DoWork += ServiceEngine;

            _save = new BackgroundWorker
            {
                WorkerSupportsCancellation = true
            };
            _save.DoWork += SaveEngine;

            _LibreHardwareMonitor = new BackgroundWorker
            {
                WorkerSupportsCancellation = true
            };
            _LibreHardwareMonitor.DoWork += LibreHardwareMonitorEngine;

            _timestamp = new DateTimeOffset(DateTime.Now).ToUnixTimeSeconds();
        }

        public void Start()
        {
            _mutex.WaitOne();
            if (!Directory.Exists(_folderPath)) Directory.CreateDirectory(_folderPath);
            if (!File.Exists(_dataFilePath)) File.WriteAllText(_dataFilePath, "");

            string JsonString = "";
            _reader = File.ReadAllLines(_configPath);
            foreach (var line in _reader)
            {
                JsonString += line;
            }

            _config = JsonSerializer.Deserialize<JsonObject>(JsonString);

            if (int.Parse(_config["COLLECT_INFO_PERIOD"].ToString()) == 0) _config["COLLECT_INFO_PERIOD"] = 1;
            if (int.Parse(_config["SAVE_INFO_PERIOD"].ToString()) == 0) _config["SAVE_INFO_PERIOD"] = 1;

            if (File.Exists(_dataSavePath))
            {
                if (!File.ReadAllBytes(_dataFilePath).SequenceEqual(File.ReadAllBytes(_dataSavePath)))
                {
                    File.Delete(_dataFilePath);
                    File.Copy(_dataSavePath, _dataFilePath);
                }
            }

            Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": Starting engines..." + "\r");
            _service.RunWorkerAsync();
            _save.RunWorkerAsync();
            _LibreHardwareMonitor.RunWorkerAsync();
            while (
                (_serviceEngine != true) &&
                (_saveEngine != true) &&
                (_LibreHardwareMonitorEngine != true)
                ) Thread.Sleep(1000);

            _allEngineState = true;
            Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": All engines started" + "\r");
            _mutex.ReleaseMutex();
        }

        public void ServiceEngine(object? sender, DoWorkEventArgs e)
        {
            Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": Service engine started" + "\r");
            _serviceEngine = true;
            while (_allEngineState != true) Thread.Sleep(100);
            Thread.Sleep(500);

            while (_stopEngineSignal == false)
            {
                _mutex.WaitOne();

                if (!Directory.Exists(_folderPath)) Directory.CreateDirectory(_folderPath);
                if (!File.Exists(_dataFilePath)) File.WriteAllText(_dataFilePath, "");

                _mutex.ReleaseMutex();

                Thread.Sleep(100);
            }
            _serviceEngine = false;
        }

        public void SaveEngine(object? sender, DoWorkEventArgs e)
        {
            Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": Save engine started" + "\r");
            _saveEngine = true;
            while (_allEngineState != true) Thread.Sleep(100);
            Thread.Sleep(500);

            while (_stopEngineSignal == false)
            {
                Thread.Sleep(int.Parse(_config["SAVE_INFO_PERIOD"].ToString()) * 1000 * 3600);

                _mutex.WaitOne();

                Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": Saving..." + "\r");
                if (File.Exists(_dataSavePath)) File.Delete(_dataSavePath);
                File.Copy(_dataFilePath, _dataSavePath);

                _mutex.ReleaseMutex();
            }

            _saveEngine = false;
        }

        public void LibreHardwareMonitorEngine(object? sender, DoWorkEventArgs e)
        {
            Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": LibreHardwareMonitor engine started" + "\r");
            _LibreHardwareMonitorEngine = true;
            while (_allEngineState != true) Thread.Sleep(100);
            Thread.Sleep(500);

            DateTime uploadTime = DateTime.Now.AddMinutes(int.Parse(_config["UPLOAD_PERIOD"].ToString()));
            JsonObject uptime = new()
            {
                { "EXIST", false },
                { "DATE", DateTime.Now.ToString("yyyy-MM-dd") },
                { "VALUE", 0 }
            };

            while (_stopEngineSignal == false)
            {
                _mutex.WaitOne();
                Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": Working on LibreHardwareMonitor engine" + "\r");

                List<string> lines = new();
                Match lineMatch;
                JsonObject consumption = LibreHardwareMonitorModel.GetConsumption();
                JsonObject data = new()
                {
                    { "CONSUMPTION", "0" },
                    { "UPTIME", "0" }
                };
               string regex = @"""(?<DATE>" + DateTime.Now.ToString("yyyy-MM-dd") + @")"": {""CONSUMPTION"":""(?<CONSUMPTION>[\s\S]+?)"",""UPTIME"":""(?<UPTIME>[0-9]+)""},";

                if (consumption != null)
                {
                    if (File.Exists(_dataFilePath))
                    {
                        _reader = File.ReadAllLines(_dataFilePath);
                        lines.Clear();
                        foreach (var line in _reader)
                        {
                            lines.Add(line);
                        }
                    }

                    for (int i = 0; i < lines.Count; i++)
                    {
                        lineMatch = Regex.Match(lines[i], regex);
                        if (lineMatch.Groups["DATE"].ToString() == DateTime.Now.Date.ToString("yyyy-MM-dd"))
                        {
                            string oldConsumption = lineMatch.Groups["CONSUMPTION"].ToString();
                            if (consumption["DATE"].ToString() != DateTime.Now.ToString("yyyy-MM-dd")) consumption["EXIST"] = false;

                            if (consumption["EXIST"].GetValue<bool>() == false)
                            {
                                consumption["EXIST"] = true;
                                if (consumption["DATE"].ToString() != DateTime.Now.ToString("yyyy-MM-dd"))
                                {
                                    oldConsumption = "0";
                                }
                                else consumption["CONSUMPTION"] = int.Parse(lineMatch.Groups["UPTIME"].Value);
                            }

                            if ((consumption["CONSUMPTION"].ToString() == "VM detected") || (oldConsumption == "VM detected"))
                            {
                                data["CONSUMPTION"] = "VM detected";
                            }
                            else data["CONSUMPTION"] = (float.Parse(oldConsumption, CultureInfo.InvariantCulture) + float.Parse(consumption["CONSUMPTION"].ToString(), CultureInfo.InvariantCulture) * int.Parse(_config["COLLECT_INFO_PERIOD"].ToString()) / 3600).ToString(CultureInfo.InvariantCulture);

                            if (uptime["DATE"].ToString() != DateTime.Now.ToString("yyyy-MM-dd")) uptime["EXIST"] = false;

                            if (uptime["EXIST"].GetValue<bool>() == false)
                            {
                                uptime["EXIST"] = true;
                                if (uptime["DATE"].ToString() != DateTime.Now.ToString("yyyy-MM-dd"))
                                {
                                    _timestamp = new DateTimeOffset(DateTime.Now).ToUnixTimeSeconds();
                                    uptime["VALUE"] = 0;
                                }
                                else uptime["VALUE"] = int.Parse(lineMatch.Groups["UPTIME"].Value);
                                uptime["DATE"] = DateTime.Now.ToString("yyyy-MM-dd");
                            }
                        }
                    }
                    data["UPTIME"] = (int.Parse(uptime["VALUE"].ToString()) + (new DateTimeOffset(DateTime.Now).ToUnixTimeSeconds() - _timestamp)).ToString();

                    if (DateTime.Now >= uploadTime)
                    {
                        Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": LibreHardwareMonitor module is writing logs..." + "\r");
                        bool todayLineExist = false;
                        for (int i = 0; i < lines.Count; i++)
                        {
                            lineMatch = Regex.Match(lines[i], regex);
                            if (lineMatch.Groups["DATE"].Value.ToString() == DateTime.Now.Date.ToString("yyyy-MM-dd"))
                            {
                                todayLineExist = true;
                                lines[i] = "\"" + DateTime.Now.Date.ToString("yyyy-MM-dd") + "\"" + ": " + JsonSerializer.Serialize(data) + ",";
                                break;
                            }
                        }
                        if (!todayLineExist)
                        {
                            lines.Add("\"" + DateTime.Now.Date.ToString("yyyy-MM-dd") + "\"" + ": " + JsonSerializer.Serialize(data) + ",");
                        }
                        if (Directory.Exists(_folderPath)) File.WriteAllLines(_dataFilePath, lines);
                        else
                        {
                            Console.WriteLine("[ERROR] " + DateTime.Now.ToString() + ": Data folder doesn't exist" + "\r");
                        }
                        uploadTime = DateTime.Now.AddMinutes(int.Parse(_config["UPLOAD_PERIOD"].ToString()));
                    }
                    _mutex.ReleaseMutex();
                    Thread.Sleep(int.Parse(_config["COLLECT_INFO_PERIOD"].ToString()) * 1000);
                }
            }
            _LibreHardwareMonitorEngine = false;
        }

        public void Stop()
        {
            _stopEngineSignal = true;

            Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": Stopping engines" + "\r");
            _service.CancelAsync();
            _LibreHardwareMonitor.CancelAsync();
            while (
                (_serviceEngine != true) &&
                (_saveEngine != true) &&
                (_LibreHardwareMonitorEngine == true)
                ) Thread.Sleep(1000);
            Thread.Sleep(1000);

            if (File.Exists(_dataFilePath))
            {
                if (File.Exists(_dataSavePath)) File.Delete(_dataSavePath);
                File.Copy(_dataFilePath, _dataSavePath);
            }

            _allEngineState = false;
            try
            {
                Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": Engines stopped" + "\r");
            }
            catch
            {
                Console.WriteLine("[ERROR] Can't write logs");
            }
        }

        public static TimeSpan GetSystemUpTime()
        {
            return TimeSpan.FromMilliseconds(Environment.TickCount);
        }
    }
}
