mod scaping_info;

use std::{
    fs::{read_to_string, File},
    io::Write,
};

use curl::easy::Easy;
use scaping_info::learndutch_hoofdpagina;
use serde::{Deserialize, Serialize};
use thirtyfour::{common::capabilities::firefox::FirefoxPreferences, prelude::*};
use tokio;

#[derive(Serialize, Deserialize, Debug, Clone)]
struct Vertaling {
    nederlands: String,
    engels: String,
    uitspraak: String,
}

impl Vertaling {
    fn new(nederlands: String, engels: String) -> Vertaling {
        let uitspraak = get_audio(&nederlands);
        Vertaling {
            nederlands,
            engels,
            uitspraak,
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct Les {
    les_naam: String,
    vertalingen: Vec<Vertaling>,
    yt_link: String,
}

impl Les {
    fn new(les_naam: String, vertalingen: Vec<Vertaling>, yt_link: String) -> Les {
        Les {
            les_naam,
            vertalingen,
            yt_link,
        }
    }
}

fn get_audio(text: &str) -> String {
    let mut url = google_translate_tts::url(text, "nl");
    url = url.replace(" ", "%20");
    let mut dst = Vec::new();
    let mut easy = Easy::new();
    easy.url(&url).unwrap();
    {
        let mut transfer = easy.transfer();
        transfer.write_function(|data| {
            dst.extend_from_slice(data);
            Ok(data.len())
        });
        transfer.perform();
    }
    base64::encode(dst.as_slice())
}

async fn start_browserdriver() -> WebDriverResult<std::process::Child> {
    let chrome = std::process::Command::new("chromedriver")
        .arg("--port=4445")
        .spawn()
        .expect("cant");
    Ok(chrome)
}

async fn new_webdriver() -> WebDriverResult<WebDriver> {
    let mut caps = DesiredCapabilities::chrome();
    // caps.add_chrome_arg("user-agent=\"Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)\"")?;
    // caps.add_chrome_option("profile.default_content_setting_values.javascript", 2)?;
    WebDriver::new("http://localhost:4445", &caps).await
}

fn sorter(this: &Les, other: &Les) -> std::cmp::Ordering {
    let get_number = |a: &Les| {
        let data = a.les_naam.split(" ").collect::<Vec<_>>();
        let num = data.get(1).unwrap();
        num.parse::<u8>().unwrap()
    };
    get_number(this).cmp(&get_number(other))
}

#[tokio::main]
async fn main() -> WebDriverResult<()> {
    let chrome = start_browserdriver().await?;
    let mut info = learndutch_hoofdpagina().await?;
    info.sort_by(sorter);
    let info_json = serde_json::to_string(&info)?;
    let mut nl_json = File::create("./nl.json")?;
    nl_json.write_all(info_json.as_bytes()).unwrap();
    Ok(())
}
