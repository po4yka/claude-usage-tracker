const INDEX_HTML: &str = include_str!("../ui/index.html");
const STYLE_CSS: &str = include_str!("../ui/style.css");
const APP_JS: &str = include_str!("../ui/app.js");

pub fn render_dashboard() -> String {
    INDEX_HTML
        .replace("/* __STYLE_CSS__ */", STYLE_CSS)
        .replace("/* __APP_JS__ */", APP_JS)
}
