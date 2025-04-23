const parse = require('set-cookie-parser');
(async () => {
    const fetch = (await import('node-fetch')).default
    let txtRes = {};
    let boxToken;

    while (!txtRes.ok) {
        txtRes = await fetch('https://wireless.wifirst.net/index.txt');
        if (!txtRes.ok) {
            console.log(`Erreur récupération index.txt: ${txtRes.status}`);
        }
        boxToken = (await txtRes.text()).trim();
    }
    console.log('✅ box_token =', boxToken);
    const payload = {
        box_token: boxToken,
        fragment_id: 2673,
        guest_user: { email: 'example@example.com', cgu: true }
    };
    const payload2 = {
        "success_url": "https://www.myresidhome.com",
        "error_url": "https://portal.wifirst.net/connect-error",
        "update_session": 0
    };

    const postRes = await fetch('https://portal.wifirst.net/api/guest_users', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        },
        body: JSON.stringify(payload)
    });

    const raw = postRes.headers.raw()['set-cookie'] || [];
    let res = await postRes.json()
    payload2.username = res.radius.login
    payload2.password = res.radius.password

    const cookies = parse.parse(raw);
    const auth = cookies.find(c => c.name === 'Portal-AuthToken');

    if (!auth) {
        console.error('❌ Pas de Portal-AuthToken dans la réponse');
        return;
    }
    console.log('✅ Portal-AuthToken =', auth.value);

    const params = new URLSearchParams();
    for (const [k, v] of Object.entries(payload2)) {
      params.append(k, v);
    }
    const headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Origin': 'https://portal.wifirst.net',
        'Referer': 'https://portal.wifirst.net/',
        'Cookie': `Portal-AuthToken=${auth.value}`,
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 OPR/117.0.0.0'
    };
    const subsequent = await fetch('https://wireless.wifirst.net/goform/HtmlLoginRequest', {
        method: 'POST',
        headers,
        body: params.toString(),
        redirect: 'manual'
    });
    console.log('Status after auth GET:', subsequent.status);
    console.log(await subsequent.statusText);
})();
