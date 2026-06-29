// =====================================================
//  Bohao Li — Academic Homepage
//  Loads YAML config + Markdown sections into the DOM.
// =====================================================

const CONTENT_DIR = 'contents/';
const CONFIG_FILE = 'config.yml';
const SECTION_NAMES = ['home', 'news', 'publications', 'awards'];


window.addEventListener('DOMContentLoaded', () => {

    /* ---- Load YAML config ---- */
    fetch(CONTENT_DIR + CONFIG_FILE)
        .then((resp) => resp.text())
        .then((text) => {
            const yml = jsyaml.load(text);
            Object.keys(yml).forEach((key) => {
                const value = yml[key];
                // 1) data-config="key" attributes
                document.querySelectorAll('[data-config="' + key + '"]').forEach((el) => {
                    el.innerHTML = value;
                });
                // 2) legacy id="key" elements
                const byId = document.getElementById(key);
                if (byId) byId.innerHTML = value;
                // 3) <title>
                if (key === 'title') {
                    document.title = value;
                }
            });
        })
        .catch((err) => console.error('config.yml load failed:', err));


    /* ---- Load Markdown sections ---- */
    marked.use({
        mangle: false,
        headerIds: false,
        gfm: true,
        breaks: false
    });

    SECTION_NAMES.forEach((name) => {
        fetch(CONTENT_DIR + name + '.md')
            .then((resp) => resp.text())
            .then((md) => {
                const html = marked.parse(md);
                const el = document.getElementById(name + '-md');
                if (el) el.innerHTML = html;
            })
            .catch((err) => console.error(name + '.md load failed:', err));
    });
});
