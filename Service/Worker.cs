using LibreHardwareMonitor.Hardware;
using System.Text.Json;
using System.Text.Json.Nodes;
using static System.Environment;

namespace Service
{
    public class Worker : BackgroundService
    {
        private JsonObject? _config;
        private readonly ILogger<Worker> _logger;
        private long _serviceTick;
        private long _collectTick;
        private long _writingTick;
        private long _saveTick;

        private String _dataPath = GetFolderPath(SpecialFolder.CommonApplicationData) + @"\GreenIT";
        private String _configFile = GetFolderPath(SpecialFolder.CommonApplicationData) + @"\GreenIT\config.json";
        private String _dataFile = GetFolderPath(SpecialFolder.CommonApplicationData) + @"\GreenIT\data.json";
        private String _dataBackupFile = GetFolderPath(SpecialFolder.CommonApplicationData) + @"\GreenIT\data.json.bak";

        public Worker(ILogger<Worker> logger)
        {
            _logger = logger;
            _serviceTick = Environment.TickCount64;
            _collectTick = Environment.TickCount64;
            _writingTick = Environment.TickCount64;
            _saveTick = Environment.TickCount64;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Initializing...");

                JsonObject? data = GetData();

                if (_config == null )
                {
                    _logger.LogError("Failed to initialize config. Exiting worker.");
                    Exit(1);
                }

                if (data == null)
                {
                    _logger.LogError("Failed to initialize data. Exiting worker.");
                    Exit(1);
                }

                _logger.LogInformation("Service initialized!");
                _logger.LogInformation("");

                while (!stoppingToken.IsCancellationRequested)
                {

                    try
                    {
                        _logger.LogInformation("Worker running at: {time}", DateTimeOffset.Now);
                    
                        FilesCheck();

                        if (_config["collect"]?["period"] is JsonNode collectNode &&
                        long.TryParse(collectNode.ToString(), out long collectPeriod))
                        {
                            // Fix data collection if collectPeriod is 0
                            if (collectPeriod == 0)
                            {
                                collectPeriod = 1; // Default to 1 second if collectPeriod is 0
                            }

                            if (collectPeriod == (Environment.TickCount64 - _collectTick) / 1000)
                            {
                                data = ApplyNewConsumption(data);
                                _collectTick = Environment.TickCount64;
                            }
                        }

                        if (_config["writing"]?["period"] is JsonNode writingNode &&
                        long.TryParse(writingNode.ToString(), out long writingPeriod))
                        {
                            if (writingPeriod == (Environment.TickCount64 - _writingTick) / 1000 / 60)
                            {
                                WriteData(SerializeData(data));
                                _writingTick = Environment.TickCount64;
                            }
                        }

                        if (_config["backup"]?["period"] is JsonNode backupNode &&
                        long.TryParse(backupNode.ToString(), out long backupPeriod))
                        {
                            if (backupPeriod == (Environment.TickCount64 - _saveTick) / 1000 / 3600)
                            {
                                BackupData();
                                _saveTick = Environment.TickCount64;
                            }
                        }

                        _logger.LogInformation("Worker run finished at: {time}", DateTimeOffset.Now);
                        _logger.LogInformation("");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "An error occurred while executing the worker.");
                    }
                    finally
                    {
                        await Task.Delay(1000, stoppingToken);
                    }
                }
            }
            catch (OperationCanceledException)
            {
                // When the stopping token is canceled, for example, a call made from services.msc,
                // we shouldn't exit with a non-zero exit code. In other words, this is expected...
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "{Message}", ex.Message);
                Environment.Exit(1);
            }
        }

        private void FilesCheck()
        {
            try
            {
                _logger.LogInformation("Checking mandatory files...");

                if (!Directory.Exists(_dataPath))
                {
                    Directory.CreateDirectory(_dataPath);
                    _logger.LogInformation($"Created data directory: {_dataPath}");
                }

                if (File.Exists(_configFile))
                {
                    _config = JsonNode.Parse(File.ReadAllText(_configFile)) as JsonObject;
                }
                else
                {
                    _config = new JsonObject
                    {
                        ["Collect"] = new JsonObject
                        {
                            ["period"] = 1 // Default to 1 second
                        },
                        ["Writing"] = new JsonObject
                        {
                            ["period"] = 0 // Default every second
                        },
                        ["backup"] = new JsonObject
                        {
                            ["period"] = 1 // Default to 1 hour
                        }
                    };
                    File.Create(_configFile).Dispose();
                    File.WriteAllText(_configFile, SerializeData(_config));
                    _logger.LogInformation($"Created config file: {_configFile}");
                }

                if (!File.Exists(_dataFile))
                {
                    File.Create(_dataFile).Dispose();
                    File.WriteAllText(_dataFile, new JsonObject().ToJsonString());
                    _logger.LogInformation($"Created data file: {_dataFile}");
                }

                _logger.LogInformation("Mandatory files check successfuly!");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while checking files.");
            }
        }

        private JsonObject? GetData()
        {
            try
            {
                FilesCheck();

                _logger.LogInformation($"Reading data from {_dataFile}...");
                JsonNode? parsedNode = JsonNode.Parse(File.ReadAllText(_dataFile));
                _logger.LogInformation($"Data has been retrieved from {_dataFile}!");

                _logger.LogInformation($"Checking data format...");
                if (parsedNode is JsonObject jsonObject)
                {
                    _logger.LogInformation($"Data format OK!");
                    return jsonObject;
                }
                else
                {
                    throw new Exception("Parsed data is not a JsonObject.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while reading data file.");
                return null;
            }
        }

        private JsonObject ApplyNewConsumption(JsonObject data)
        {
            JsonObject dataBackup = data;

            try
            {
                _logger.LogInformation("Applying new consumption to retrieved data...");

                String currentDate = DateTime.Now.ToString("yyyy-MM-dd");
                float consumption = GetConsumption();

                if (data.ContainsKey(currentDate))
                {
                    if (data[currentDate] is JsonObject currentDateData)
                    {
                        if (currentDateData["consumption"] is JsonNode consumptionNode &&
                            float.TryParse(consumptionNode.ToString(), out float existingConsumption))
                        {
                            currentDateData["consumption"] = existingConsumption + consumption;
                        }
                        else
                        {
                            _logger.LogWarning($"Consumption data for {currentDate} is invalid. Overwriting with new data.");
                            currentDateData["consumption"] = consumption;
                        }

                        if (currentDateData["uptime"] is JsonNode uptimeNode &&
                            int.TryParse(uptimeNode.ToString(), out int existingUptime))
                        {
                            currentDateData["uptime"] = existingUptime + ((Environment.TickCount64 - _serviceTick) / 1000);
                            _serviceTick = Environment.TickCount64;
                        }
                        else
                        {
                            _logger.LogWarning($"Uptime data for {currentDate} is invalid. Overwriting with new data.");
                            currentDateData["uptime"] = (Environment.TickCount64 - _serviceTick) / 1000;
                            _serviceTick = Environment.TickCount64;
                        }
                    }
                    else
                    {
                        _logger.LogWarning($"Data for {currentDate} is not a JsonObject. Overwriting with new data.");
                        data[currentDate] = new JsonObject
                        {
                            ["consumption"] = consumption,
                            ["uptime"] = (Environment.TickCount64 - _serviceTick) / 1000
                        };
                        _serviceTick = Environment.TickCount64;
                    }
                }
                else
                {
                    data[currentDate] = new JsonObject
                    {
                        ["consumption"] = consumption,
                        ["uptime"] = (Environment.TickCount64 - _serviceTick) / 1000
                    };
                    _serviceTick = Environment.TickCount64;
                }

                _logger.LogInformation("New consumption applied successfuly!");
                return data;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while applying new data.");
                return dataBackup;
            }
        }

        private void WriteData(String? data)
        {
            try
            {
                _logger.LogInformation($"Writing data into {_dataFile}...");
                File.WriteAllText(_dataFile, data);
                _logger.LogInformation($"Data written into {_dataFile}!");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while writing data file.");
            }
        }

        private void BackupData()
        {
            try
            {
                _logger.LogInformation($"Backuping data into {_dataBackupFile}");
                File.Copy(_dataFile, _dataBackupFile, true);
                _logger.LogInformation($"Sccessful backup has been created into {_dataBackupFile}!");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while backuping data file.");
            }
        }

        public float GetConsumption()
        {
            try
            {
                _logger.LogInformation("Getting computer consumption...");

                if (_config == null)
                {
                    _logger.LogError("config object cannot be null. Exiting worker.");
                    Exit(1);
                }

                Computer computer = new Computer
                {
                    IsCpuEnabled = true,
                    IsGpuEnabled = true,
                    IsMemoryEnabled = true,
                    IsMotherboardEnabled = true,
                    IsControllerEnabled = true,
                    IsNetworkEnabled = true,
                    IsStorageEnabled = true
                };

                computer.Open();
                computer.Accept(new UpdateVisitor());

                float consumption = 0.0f;

                foreach (IHardware hardware in computer.Hardware)
                {
                    _logger.LogDebug("Hardware: {0}", hardware.Name);

                    foreach (IHardware subhardware in hardware.SubHardware)
                    {
                        _logger.LogDebug("\tSubhardware: {0}", subhardware.Name);

                        foreach (ISensor sensor in subhardware.Sensors)
                        {
                            if (sensor.SensorType.Equals(SensorType.Power))
                            {
                                _logger.LogDebug("\t\tSensor: {0}, value: {1}", sensor.Name, sensor.Value);
                                consumption += sensor.Value.HasValue ? sensor.Value.Value : 0;
                            }
                        }
                    }

                    foreach (ISensor sensor in hardware.Sensors)
                    {
                        if (sensor.SensorType.Equals(SensorType.Power))
                        {
                            _logger.LogDebug("\t\tSensor: {0}, value: {1}", sensor.Name, sensor.Value);
                            consumption += sensor.Value.HasValue ? sensor.Value.Value : 0;
                        }
                    }
                }

                computer.Close();

                if (_config["collect"]?["period"] is JsonNode collectNode &&
                        long.TryParse(collectNode.ToString(), out long collectPeriod))
                {
                    // Fix data collection if collectPeriod is 0
                    if (collectPeriod == 0)
                    {
                        collectPeriod = 1; // Default to 1 second if collectPeriod is 0
                    }

                    consumption = consumption * collectPeriod;
                }

                _logger.LogInformation("Computer consumption retrived successfuly!");
                return consumption;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while getting consumption data.");
                return 0.0f;
            }
        }

        private String? SerializeData(JsonObject data)
        {
            try
            {
                _logger.LogInformation("Serializing data...");
                return JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while serializing data.");
                return null;
            }
        }

        internal class UpdateVisitor : IVisitor
        {
            public void VisitComputer(IComputer computer)
            {
                computer.Traverse(this);
            }
            public void VisitHardware(IHardware hardware)
            {
                hardware.Update();
                foreach (IHardware subHardware in hardware.SubHardware) subHardware.Accept(this);
            }
            public void VisitSensor(ISensor sensor) { }
            public void VisitParameter(IParameter parameter) { }
        }
    }
}
