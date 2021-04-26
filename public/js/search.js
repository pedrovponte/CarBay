function update_time_remaining() {
    let auctions = document.querySelectorAll("#time-remaining")

    for (const auction of auctions) {
        let final_date = auction.getAttribute("data-time");
        let date2 = new Date(final_date);
        let date1 = new Date();
        var diff = new Date(date2.getTime() - date1.getTime());
        var new_time = `${Math.floor(diff.getTime() / (1000 * 3600 * 24))}d ${diff.getHours()}h ${diff.getMinutes()}m ${diff.getSeconds()}s`;

        auction.querySelector("#time-remaining-value").innerHTML = new_time;
    }
}

setInterval(update_time_remaining, 1000)

function encodeForAjax(data) {
    if (data == null) return null;
    return Object.keys(data).map(function (k) {
        return encodeURIComponent(k) + '=' + encodeURIComponent(data[k])
    }).join('&');
}

function sendAjaxRequest(method, url, data, handler) {
    let request = new XMLHttpRequest();

    request.open(method, url, true);
    request.setRequestHeader('X-CSRF-TOKEN', document.querySelector('meta[name="csrf-token"]').content);
    request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    request.addEventListener('load', handler);
    request.send(encodeForAjax(data));
}

function setSelect(response, attribute = "name") {
    let objects = JSON.parse(response)

    let new_objects = []

    for (const object of objects) {
        let new_object = {'id': object.id, [attribute]: object[attribute]}
        new_objects.push(new_object);
    }

    return new_objects
}

function setColours() {
    let colours = setSelect(this.responseText)
    
    let select = document.querySelector("#select-colour")

    for (const colour of colours) {
        select.insertAdjacentHTML('beforeend', `<option value="${colour.id}">${colour.name}</option>`)
    }
}

function setBrands() {
    let brands = setSelect(this.responseText)
    
    let select = document.querySelector("#select-brand")

    for (const brand of brands) {
        select.insertAdjacentHTML('beforeend', `<option value="${brand.id}">${brand.name}</option>`)
    }
}

function setScales() {
    let scales = setSelect(this.responseText)
    
    let select = document.querySelector("#select-scale")

    for (const scale of scales) {
        select.insertAdjacentHTML('beforeend', `<option value="${scale.id}">${scale.name}</option>`)
    }
}

function setSellers() {
    let sellers = JSON.parse(this.responseText)
    
    let select = document.querySelector("#select-seller")

    select.insertAdjacentHTML('beforeend', '<optgroup label="Favourites">')

    for (const seller of sellers.favourites) {
        select.insertAdjacentHTML('beforeend', `<option value="${seller.id}">${seller.username}</option>`)
    }

    select.insertAdjacentHTML('beforeend', '</optgroup><optgroup label="All">')

    for (const seller of sellers.all) {
        select.insertAdjacentHTML('beforeend', `<option value="${seller.id}">${seller.username}</option>`)
    }
    select.insertAdjacentHTML('beforeend', '</optgroup>')
}

function getColours() {
    sendAjaxRequest('GET','/api/colours', {}, setColours)
}

function getBrands() {
    sendAjaxRequest('GET','/api/brands', {}, setBrands)
}

function getScales() {
    sendAjaxRequest('GET','/api/scales', {}, setScales)
}

function getSellers() {
    sendAjaxRequest('GET','/api/sellers', {}, setSellers)
}

function getAllSelectData() {
    getColours()
    getBrands()
    getScales()
    getSellers()
}

getAllSelectData()