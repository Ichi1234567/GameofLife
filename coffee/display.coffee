define([
    "color"
], (COLOR) ->
    console.log("display")
    _Math = Math
    _Doc = document

    $.fn.showCanvas = (params) ->
        if (!params)
            return
        w = if (params.w) then (params.w) else (400)
        h = if (params.h) then (params.h) else (400)
        num = params.num
        g_num = [w / num, h / num]
        data = params.data

        #console.log(data)
        canvas = _Doc.createElement("canvas")
        canvas.width = w
        canvas.height = h
        ctx = canvas.getContext("2d")
        ctx.lineCap = "round"
        ctx.lineJoin = "miterLimit"
        ctx.fillStyle = "#" + COLOR.empty[0]
        ctx.clearRect(0, 0, w, h)
        ctx.beginPath()
        ctx.fillRect(0, 0, w, h)
        data.forEach((data_i) ->
            type_i = data_i.type
            if (type_i != "empty")
                pos_i = data_i.position
                ghost = data_i.ghost
                r_i = _Math.floor(pos_i / num)
                c_i = pos_i % num
                ctx.fillStyle = "#" + COLOR[type_i][ghost]
                ctx.fillRect(g_num[0] * r_i, g_num[1] * c_i, g_num[0], g_num[1])
        )
        ctx.closePath()

        $(canvas).addClass("panel")
        $(@).append(canvas)
        @

    $.fn.upCanvas = (cells, params) ->
        if (!cells || !params)
            return
        canvas = $(@).find("canvas").get(0)
        ctx = canvas.getContext("2d")
        w = canvas.width
        h = canvas.height
        num = params.num
        g_num = [w / num, h / num]
        ctx.beginPath()
        cells.forEach((data_i) ->
            type_i = data_i.type
            pos_i = data_i.position
            ghost = data_i.ghost
            r_i = _Math.floor(pos_i / num)
            c_i = pos_i % num
            ctx.fillStyle = "#" + COLOR[type_i][ghost]
            ctx.fillRect(g_num[0] * r_i, g_num[1] * c_i, g_num[0], g_num[1])
            data_i.visited = false
        )
        ctx.closePath()
        @
)

