class UserInfo extends Widget
    constructor: (@id, name, img_src)->
        super
        @img = create_img("UserImg", img_src, @element)
        @name = create_element("span", "UserName", @element)
        @name.innerText = name


u = new UserInfo(1000, "Alice Charlotte", "images/img01.jpg")
roundabout = create_element("div", "roundabout", document.body)
roundabout.appendChild(u.element)
