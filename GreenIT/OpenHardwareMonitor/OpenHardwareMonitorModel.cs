using OpenHardwareMonitor.Hardware;
using System.Text.Json.Nodes;

namespace GreenIT.OpenHardwareMonitor
{
    public static class OpenHardwareMonitorModel
    {
        private static readonly UpdateVisitor _visitor = new();
        private static readonly Computer _computer = new();
        public static JsonObject GetConsumption()
        {
            JsonObject consumption = new();
            _computer.Open();
            _computer.CPUEnabled = true;
            _computer.Accept(_visitor);
            for (int i = 0; i < _computer.Hardware.Length; i++)
            {
                if (_computer.Hardware[i].HardwareType == HardwareType.CPU)
                {
                    for (int j = 0; j < _computer.Hardware[i].Sensors.Length; j++)
                    {
                        if ((_computer.Hardware[i].Sensors[j].SensorType == SensorType.Power) && (_computer.Hardware[i].Sensors[j].Name == "Package Power"))
                        {
                            consumption.Add("EXIST", true);
                            consumption.Add("DATE", DateTime.Now.ToString("yyyy-MM-dd"));
                            if (_computer.Hardware[i].Sensors[j].Value > 50000) consumption.Add("CONSUMPTION", "VM detected");
                            else
                            {
                                consumption.Add("CONSUMPTION", _computer.Hardware[i].Sensors[j].Value.ToString());
                            }
                        }
                    }
                }
            }
            _computer.Close();
            return consumption;
        }
    }
}
