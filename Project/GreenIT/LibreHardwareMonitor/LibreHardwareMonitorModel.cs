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
            _computer.IsMotherboardEnabled = true;
            _computer.Accept(_visitor);
            foreach (IHardware hardware in _computer.Hardware)
            {
                Console.WriteLine("Hardware: {0}", hardware.Name);

                foreach (IHardware subhardware in hardware.SubHardware)
                {
                    Console.WriteLine("\tSubhardware: {0}", subhardware.Name);

                    foreach (ISensor sensor in subhardware.Sensors)
                    {
                        Console.WriteLine("\t\tSensor: {0}, value: {1}", sensor.Name, sensor.Value);
                    }
                }

                foreach (ISensor sensor in hardware.Sensors)
                {
                    Console.WriteLine("\tSensor: {0}, value: {1}", sensor.Name, sensor.Value);
                }
            }
            /*for (int i = 0; i < _computer.Hardware.; i++)
            {
                if (_computer.Hardware[i].HardwareType == HardwareType.Cpu)
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
                                consumption.Add("CONSUMPTION", _computer.Hardware[i].Sensors[j].Value.ToString().Replace(',', '.'));
                            }
                        }
                    }
                }
            }*/
            _computer.Close();
            return consumption;
        }
    }
}
