using LibreHardwareMonitor.Hardware;
using System.Text.Json.Nodes;

namespace GreenIT.LibreHardwareMonitor
{
    public static class LibreHardwareMonitorModel
    {
        private static readonly UpdateVisitor _visitor = new();
        private static readonly Computer _computer = new();
        public static JsonObject GetConsumption()
        {
            JsonObject consumption = new();
            _computer.Open();
            _computer.IsCpuEnabled = true;
            _computer.Accept(_visitor);
            foreach (IHardware hardware in _computer.Hardware)
            {
                foreach (ISensor sensor in hardware.Sensors)
                {
                    if(sensor.SensorType == SensorType.Power && sensor.Name == "Package")
                    {
                        consumption.Add("EXIST", true);
                        consumption.Add("DATE", DateTime.Now.ToString("yyyy-MM-dd"));
                        if (sensor.Value > 50000) consumption.Add("CONSUMPTION", "VM detected");
                        else
                        {
                            consumption.Add("CONSUMPTION", sensor.Value.ToString().Replace(",", "."));
                        }
                    }
                }
            }
            _computer.Close();
            return consumption;
        }
    }
}
