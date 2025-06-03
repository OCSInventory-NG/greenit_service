using Serilog;
using Service;

namespace GreenIT
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }
        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .UseWindowsService(options =>
                {
                    options.ServiceName = "GreenIT Service";
                })
                .UseSerilog()
                .ConfigureServices((hostContext, services) =>
                {
                    Log.Logger = new LoggerConfiguration()
                        .ReadFrom.Configuration(hostContext.Configuration)
                        .Enrich.FromLogContext()
                        .CreateLogger();
                    services.AddHostedService<Worker>();
                });
    }
}