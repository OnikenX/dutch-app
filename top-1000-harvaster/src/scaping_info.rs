use std::sync::{Mutex, Arc};

use futures::{future::join_all, TryFutureExt};
use thirtyfour::{prelude::WebDriverResult, By};
use tokio::sync::Semaphore;

use crate::{new_webdriver, Vertaling, Les};

// This function, with the webdriver, gets the various
pub async fn learndutch_hoofdpagina() -> WebDriverResult<Vec<Les>> {
    // Navigate to go to the learn dutch website
    let driver = new_webdriver().await?;
    driver
        .get("https://www.learndutch.org/online-dutch-course/")
        .await?;
    let lessons_list = driver
        .find_element(By::Id("lessons_list"))
        .await?
        .find_elements(By::Tag("a"))
        .await?;

    let words = Arc::new(Mutex::new(vec![]));

    let mut joins = vec![];
    let sem = Arc::new(Semaphore::new(20));
    for lesson in lessons_list {
        let lesson_text = lesson.text().await?;
        if lesson_text.contains("Review tests") || lesson_text.contains("Exam") {
            continue;
        }
        let lesson_link = lesson.get_attribute("href").await?.unwrap();
        println!("Les naam: {lesson_text}");
        println!("Lesson link: {lesson_link}");
        let words_tmp = words.clone();
        let sem = sem.clone();
        joins.push(tokio::spawn( async move {
            let _permit = sem.acquire().await.unwrap();
            let (woorden, yt_link) = ophalen_woordenlijst(&lesson_link).await.unwrap();
            words_tmp
                .lock()
                .unwrap()
                .push(Les::new(lesson_text, woorden, yt_link));
               
        }));
        
    }
    for join in joins {
        let _ = tokio::join!(join);
    }

    let mut free_words = vec![];
    {
        free_words.append(words.lock().unwrap().as_mut());
    }
    driver.quit().await?;
    Ok(free_words)
}

async fn ophalen_woordenlijst(link_lesson: &str) -> WebDriverResult<(Vec<Vertaling>, String)> {
    let driver = new_webdriver().await?;
    driver.get(link_lesson).await?;
    let mut words = vec![];

    let yt_link = driver
        .find_element(By::ClassName("learndash_content"))
        .await?.find_element(By::Tag("iframe")).await?.get_attribute("src").await?.or_else(||Some(String::from("https://www.youtube.com/playlist?list=PLUOa-qvvZolDeAYFOPqHRC9w8Nnx5cTcJ"))).unwrap();
    
    let mut translations = driver
        .find_element(By::ClassName("learndash_content"))
        .await?
        .find_element(By::Tag("table"))
        .await?
        .find_element(By::Tag("tbody"))
        .await?
        .find_elements(By::Tag("tr"))
        .await?;
    translations.remove(0);
    for translation in translations {
        let pair = translation.find_elements(By::Tag("td")).await?;

        words.push(Vertaling::new(
            pair.get(0).unwrap().text().await?,
            pair.get(1).unwrap().text().await?,
        ));
    }
    let _ = driver.quit().await?;
    Ok((words, yt_link))
}
