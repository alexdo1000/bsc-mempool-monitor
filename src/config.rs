use clap::{App, Arg};

#[derive(Debug, Clone)]
pub struct Config {
    pub ws_url: String,
    pub report_interval: u64,
}

impl Config {
    pub fn from_args() -> Self {
        let matches = App::new("BSC Mempool Monitor")
            .version("1.0")
            .about("Monitors BSC mempool for new transactions")
            .arg(Arg::with_name("ws_url")
                .short('w')
                .long("ws")
                .value_name("WS_URL")
                .help("WebSocket URL of your BSC node")
                .default_value("ws://localhost:8576")
                .takes_value(true))
            .arg(Arg::with_name("report_interval")
                .short('i')
                .long("interval")
                .value_name("SECONDS")
                .help("Interval in seconds between statistics reports")
                .default_value("60")
                .takes_value(true))
            .get_matches();

        Self {
            ws_url: matches.value_of("ws_url").unwrap().to_string(),
            report_interval: matches.value_of("report_interval").unwrap().parse().unwrap_or(60),
        }
    }
} 