using GreenIT.OpenHardwareMonitor;
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
        private bool _openHardwareMonitorEngine = false;
        private bool _stopEngineSignal = false;

        private Mutex _mutex;
        private readonly BackgroundWorker _service;
        private readonly BackgroundWorker _save;
        private readonly BackgroundWorker _openHardwareMonitor;

        private string _folderPath = @"C:\ProgramData\GreenIT";
        private string _dataFilePath = @"C:\ProgramData\GreenIT\data.json";
        private string _dataSavePath = @"C:\ProgramData\GreenIT\data.json.bak";
        private string _configPath = @"config.json";

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

            _openHardwareMonitor = new BackgroundWorker
            {
                WorkerSupportsCancellation = true
            };
            _openHardwareMonitor.DoWork += OpenHardwareMonitorEngine;

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

#pragma warning disable CS8601 // Possible null reference assignment.
            _config = JsonSerializer.Deserialize<JsonObject>(JsonString);
#pragma warning restore CS8601 // Possible null reference assignment.

#pragma warning disable CS8602 // Dereference of a possibly null reference.
            if (int.Parse(_config["COLLECT_INFO_PERIOD"].ToString()) == 0) _config["COLLECT_INFO_PERIOD"] = 1;
            if (int.Parse(_config["SAVE_INFO_PERIOD"].ToString()) == 0) _config["SAVE_INFO_PERIOD"] = 1;
#pragma warning restore CS8602 // Dereference of a possibly null reference.


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
            _openHardwareMonitor.RunWorkerAsync();
            while (
                (_serviceEngine != true) &&
                (_saveEngine != true) &&
                (_openHardwareMonitorEngine != true)
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
#pragma warning disable CS8602 // Dereference of a possibly null reference.
                Thread.Sleep(int.Parse(_config["SAVE_INFO_PERIOD"].ToString()) * 1000 * 3600);
#pragma warning restore CS8602 // Dereference of a possibly null reference.

                _mutex.WaitOne();

                Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": Saving..." + "\r");
                if (File.Exists(_dataSavePath)) File.Delete(_dataSavePath);
                File.Copy(_dataFilePath, _dataSavePath);

                _mutex.ReleaseMutex();
            }

            _saveEngine = false;
        }

        public void OpenHardwareMonitorEngine(object? sender, DoWorkEventArgs e)
        {
            Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": OpenHardwareMonitor engine started" + "\r");
            _openHardwareMonitorEngine = true;
            while (_allEngineState != true) Thread.Sleep(100);
            Thread.Sleep(500);

#pragma warning disable CS8602 // Dereference of a possibly null reference.
            DateTime uploadTime = DateTime.Now.AddMinutes(int.Parse(_config["UPLOAD_PERIOD"].ToString()));
#pragma warning restore CS8602 // Dereference of a possibly null reference.
            JsonObject uptime = new();
            uptime.Add("EXIST", false);
            uptime.Add("DATE", DateTime.Now.ToString("yyyy-MM-dd"));
            uptime.Add("VALUE", 0);

            while (_stopEngineSignal == false)
            {
                _mutex.WaitOne();
                Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": Working on OpenHardwareMonitor engine" + "\r");

                List<string> lines = new();
                Match lineMatch;
                JsonObject consumption = OpenHardwareMonitorModel.GetConsumption();
                JsonObject data = new();
                data.Add("CONSUMPTION", "0");
                data.Add("UPTIME", "0");
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
#pragma warning disable CS8602 // Dereference of a possibly null reference.
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
#pragma warning restore CS8602 // Dereference of a possibly null reference.

                    if (DateTime.Now >= uploadTime)
                    {
                        Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": OpenHardwareMonitor module is writing logs..." + "\r");
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
#pragma warning disable CS8602 // Dereference of a possibly null reference.
                        uploadTime = DateTime.Now.AddMinutes(int.Parse(_config["UPLOAD_PERIOD"].ToString()));
#pragma warning restore CS8602 // Dereference of a possibly null reference.
                    }
                    _mutex.ReleaseMutex();
#pragma warning disable CS8602 // Dereference of a possibly null reference.
                    Thread.Sleep(int.Parse(_config["COLLECT_INFO_PERIOD"].ToString()) * 1000);
#pragma warning restore CS8602 // Dereference of a possibly null reference.
                }
            }
            _openHardwareMonitorEngine = false;
        }

        public void Stop()
        {
            _stopEngineSignal = true;

            Console.WriteLine("[INFO] " + DateTime.Now.ToString() + ": Stopping engines" + "\r");
            _service.CancelAsync();
            _openHardwareMonitor.CancelAsync();
            while (
                (_serviceEngine != true) &&
                (_saveEngine != true) &&
                (_openHardwareMonitorEngine == true)
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
