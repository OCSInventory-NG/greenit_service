using GreenIT.Service;
using Topshelf;

namespace GreenIT
{
    public class GreenITMain
    {
        public static void Main(string[] args)
        {
            var exitCode = HostFactory.Run(hostConfigurator =>
            {
                hostConfigurator.Service<GreenITService>(serviceConfigurator =>
                {
                    serviceConfigurator.ConstructUsing(GreenIT => new GreenITService());
                    serviceConfigurator.WhenStarted(GreenIT => GreenIT.Start());
                    serviceConfigurator.WhenStopped(GreenIT => GreenIT.Stop());
                });
                hostConfigurator.SetServiceName("GreenITService");
                hostConfigurator.SetDisplayName("GreenIT Service");
                hostConfigurator.SetDescription("Return power consumption of the machine");
                hostConfigurator.StartAutomatically();
                hostConfigurator.RunAsLocalSystem();
            });
            int exitCodevalue = (int)Convert.ChangeType(exitCode, exitCode.GetTypeCode());
            Environment.ExitCode = exitCodevalue;
        }
    }
}
