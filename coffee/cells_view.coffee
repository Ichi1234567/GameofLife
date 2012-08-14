define([
    "basic_cell",
    "role_cell",
    "food_cell",
    "enemy_cell",
    "display",
    "rule"
], (BASIC, ROLE, FOOD, ENEMY, DISPLAY, RULE) ->
    console.log("cells_view")
    _Math = Math
    cell_model = {
        empty: BASIC,
        role: ROLE,
        food: FOOD,
        enemy: ENEMY
    }
    global_timmer = null
    global_count = 0
    prev_status = null
    Frames = 0
    UpdateTime = 1000
    LastTime = new Date()
    Fps = 0

    window.requestAnimationFrame = (() ->
        (
            window.webkitRequestAnimationFrame ||
            window.mozRequestAnimationFrame ||
            window.oRequestAnimationFrame ||
            window.msRequestAnimationFrame ||
            #function FrameRequestCallback, DOMElement Element 
            (callback, element) ->
                window.setTimeout( callback, 1000 / 60 )
        )
    )()

    window.cancelRequestAnimFrame = (() ->
        (
            window.cancelAnimationFrame ||
            window.webkitCancelRequestAnimationFrame ||
            window.mozCancelRequestAnimationFrame ||
            window.oCancelRequestAnimationFrame ||
            window.msCancelRequestAnimationFrame ||
            clearTimeout
        )
    )()


    ROUTINES = {
        evalSet: (num, ghost_num, opts) ->
            ghost_num = if (ghost_num) then (ghost_num) else (0)
            _base = if (opts.base) then (opts.base) else (0.27)
            _type = if (opts.type) then (opts.type) else ("role")
            _avgSB = if (opts.avgSB) then (opts.avgSB) else (0)
            # 先算base
            _base *= _Math.cos(_avgSB / 9)
            # 用ghost調整
            _base *= (1 + ghost_num / 40)
            #console.log("ori-base：" + _base)
            #console.log("_avg：" + _avgSB)
            #console.log("base：" + _base)

            _Math.round(num * _base)

        sortSets: (sets, opts) ->
            _num = opts.num
            _empty = _num
            sets.forEach((elm, idx) ->
                _empty -= elm.num
            )
            sets.push({
                name: "empty",
                num: _empty
            })
            sets = sets.sort((a, b) ->
                a.num - b.num
            )

            count = 0
            sets = sets.map((set_i) ->
                count += set_i.num
                set_i.rate = count / _num
                set_i
            )
            sets
        generateSets: (totalNum, opts) ->
            opts = if (opts) then (opts) else ({})
            _types = if (opts.types) then (opts.types) else (["role"])
            _ghost = if (opts.ghost) then (opts.ghost) else (0)
            _base = if (opts.base) then (opts.base) else (0.27)
            _avgSB = if (opts.avgSB) then (opts.avgSB) else (0)
            tmp_sets = _types.map((type_i) ->
                num = ROUTINES.evalSet(totalNum, _ghost, {
                    base: _base,
                    type: type_i
                    avgSB: _avgSB
                })
                {
                    name: type_i
                    num: num
                }
            )
            sets = ROUTINES.sortSets(tmp_sets, {
                num: totalNum
            })
            sets
    }

    SCENE = Backbone.View.extend({
        initialize: (params) ->
            params = if (params) then (params) else ({})
            @num = if (params.num) then (params.num) else (64)
            _num = @num
            @size = _Math.ceil(_Math.sqrt(_num))
            @w = if (params.w) then (params.w) else (300)
            @h = if (params.h) then (params.h) else (300)
            _w = @w
            _h = @h
            @current = 0
            _saveWorker = new Worker("javascript/saveCurrent.js")
            @saveWorker = _saveWorker
            _this = @
            _saveWorker.addEventListener("message", (e) ->
                _this.state = e.data
            , false)
            _moveWorker = new Worker("javascript/moveWorker.js")
            _types = {
                empty: BASIC,
                role: ROLE,
                food: FOOD,
                enemy: ENEMY
            }
            _size = @size
            $plant = $(".plant")
            _moveWorker.addEventListener("message", (e) ->
                data = e.data
                #console.log(data)
                stable = data.stable
                if (typeof stable == "boolean")
                    #console.log(data.id)
                    cell = data.cell
                    _len = cell.length
                    i = -1
                    up_cells = []
                    while (++i < _len)
                        cell_i = cell[i]
                        up_cells.push(cell_i)
                        posi = cell_i.position
                        #console.log(_this.cells[posi].type + " , " + cell.type)
                        (_this.cells[posi].type != cell_i.type && (
                            _this.cells[posi] = new _types[cell_i.type]({position: posi})
                        ))
                        (_this.cells[posi].type == cell_i.type && (
                            _this.cells[posi].ghost = cell_i.ghost
                            _this.cells[posi].lifecycle = cell_i.lifecycle
                        ))
                        #console.log(stable)
                    #console.log(_this.cells[posi])
                    #console.log(stable)
                    (!(stable) && $plant.each((idx, elm) ->
                        $(elm).upCanvas(up_cells, {num: _size})
                    ))
            , false)
            @moveWorker = _moveWorker


            $(".plant").eq(1).css("top", -(_h + 7))
            @chk_opts()
            @reset("init")
            @
        "events": {
            "click #reset": "click_reset"
            "click #next": "next"
            "click #auto-run": "auto_run"
            "change #mode": "chg_opts"
            "change #rnd_ghost": "chg_opts"
            "change #chk-delay": "chg_opts"
        }
        render: () ->
            @
        remove: () ->
            @


        auto_run: (e, status) ->
            _$target = $(e.target)
            if (!status)
                _running = !!(_$target.attr("class"))
                _$target.toggleClass("running")
            _view = @

            if (_running && !status)
                _stable = true
            else
                _$target.html("stop")
                _stable = false
                (global_timmer && cancelRequestAnimFrame(global_timmer))
                global_timmer = requestAnimationFrame(() ->
                    _view.auto_run(e, true)
                    _stable =_view.next()
                )

            if (_stable)
                _$target.html("auto-run")
                cancelRequestAnimFrame(global_timmer)
                global_timmer = null
            else
                curr_time = new Date()
                Frames++
                dt = curr_time.getTime() - LastTime.getTime()
                if (dt > UpdateTime)
                    _fps = _Math.round((Frames/dt) * UpdateTime)
                    Frames = 0
                    LastTime = curr_time
                    $("#fps").html(_fps)
            @
        chg_opts: (e) ->
            _$target = $(e.target)
            _rule = $("#mode option:selected").html().split("/")
            _is_auto_run = $("#auto-run").attr("class") == "running"
            switch (true)
                when (_$target.is("#mode"))
                    (_is_auto_run && $("#auto-run").trigger("click"))
                    @chk_opts()
                    @reset()
                when (_$target.is("#chk-delay"))
                    @chk_opts()
                when (_rule[2].length && _rule[2] != " ")
                    @chk_opts()
                    (!_is_auto_run && @reset())
            @
        click_reset: () ->
            _is_auto_run = $("#auto-run").attr("class") == "running"
            (_is_auto_run && $("#auto-run").trigger("click"))
            @reset()

        chk_opts: () ->
            _chk_delay = !!$("#chk-delay").attr("checked")
            _rule = $("#mode option:selected").html().split("/")
            sum = 0
            _len = 0
            i = 2
            while (--i > -1)
                ((i) ->
                    _rule[i].split("").forEach((val) ->
                        _val = parseInt(val)
                        (!isNaN(_val) && (sum += _val))
                    )
                    _len += _rule[i].length
                )(i)
            @cellSet = ROUTINES.generateSets(@num, {
                ghost: parseInt(_rule[2]),
                base: if (_chk_delay) then (0.2) else (0.27)
                #avgSB: _Math.round(sum / _len)
                avgSB: (_rule[0].length + _rule[1].length) / 2
            })
            @
        reset: (init) ->
            #console.log("click")
            global_count = 0
            @cells = @set(@cellSet)
            _num = @num
            _cells = @cells
            _w = @w
            _h = @h
            _size = @size
            _current = @current
            @saveWorker.postMessage(_cells)
            $(".plant").each((idx, elm) ->
                _chk = idx - _current
                $elm = $(elm)
                $(elm).html("").showCanvas({
                    w: _w,
                    h: _h,
                    num: _size
                    data: _cells
                })
                ($elm.css("visibility") == "visible" && $elm.css("hidden"))
                ($elm.css("visibility") != "visible" && $elm.css("visible"))
                true
            )
            @current = (_current + 1) % 2
            @

        next: () ->
            #console.log("click next")
            _current = @current
            _cells = @cells
            _num = @num
            _state = @state
            _stable = true
            mode = $("#mode option:selected").val()
            _chk_delay = !!$("#chk-delay").attr("checked")
            c_size = @size
            canvas = $("canvas").eq(_current).get(0)
            ctx = canvas.getContext("2d")
            g_num = [@w / c_size, @h / c_size]

            get_nei = (total_cells, thisCell, state, opts) ->
                position = thisCell.position
                c_size = opts.c_size
                ctx = opts.ctx
                g_num = opts.g_num
                result = { stable: true }

                up_cells = []
                base_pos = [
                    (position % c_size) * g_num[0] + g_num[0] / 2,
                    _Math.floor(position / c_size) * g_num[1] + g_num[1] / 2
                ]
                delta = [
                    [-1, -1, (-c_size - 1)], [0, -1, -c_size], [1, -1, (-c_size + 1)],
                    [-1, 0, -1], [1, 0, 1],
                    [-1, 1, (c_size - 1)], [0, 1, c_size], [1, 1, (c_size + 1)]
                ]
                delta.forEach((delta_i, idx) ->
                    pos_i = [
                        base_pos[0] + delta_i[0] * g_num[0],
                        base_pos[1] + delta_i[1] * g_num[1]
                    ]
                
                    cell_i = total_cells[position + delta_i[2]]
                    (ctx.getImageData(pos_i[0], pos_i[1], 1 , 1).data[3] && !cell_i.visited && (
                        up_cells.push(cell_i)
                    ))
                )
                up_cells

            _args = {
                empty: BASIC,
                role: ROLE,
                food: FOOD,
                enemy: ENEMY,
                delay: _chk_delay,
                c_size: c_size
                ctx: ctx
                g_num: g_num
            }

            i = -1

            #cell_i = _cells[0]
            #cell_nei = get_nei(_cells, cell_i, _state, _args)
            #@moveWorker.postMessage({
            #    cell: cell_i,
            #    nei: cell_nei,
            #    rule: RULE[mode],
            #    delay: _chk_delay
            #})
            _moveWorker = @moveWorker
            _w_cell = []
            _w_nei = []
            _iden = 100
            while (++i < _num)
                if (!(i % _iden))
                    _w_cell = []
                    _w_nei = []
                
                cell_i = _cells[i]
                _w_cell.push(cell_i)
                _w_nei.push(get_nei(_cells, cell_i, _state, _args))
                (!((i + 1) % _iden) &&
                    _moveWorker.postMessage({
                        id: i,
                        cell: _w_cell,
                        nei: _w_nei,
                        rule: RULE[mode],
                        delay: _chk_delay
                    })
                )
                #result = cell_i.move(_state, _cells, mode, _args)
                #(!result.stable && (_stable = false))
                #_cells = result.cells
                
            #@cells = _cells
            #_w = @w
            #_h = @h
            #@saveWorker.postMessage(_cells)
            #_state = @state
            #if (!_stable)
            #    $(".plant").each((idx, elm) ->
            #        $elm = $(elm)
            #        ($elm.css("visibility") == "visible" && (
            #            $elm.css("visibility", "hidden")
            #        ))
            #        ($elm.css("visibility") != "visible" && (
            #            $elm.upCanvas(_cells, {num: c_size}).css("visibility", "visible")
            #        ))
            #        true
            #    )
            #@current = (_current + 1) % 2
            #(_stable && !prev_status && (prev_status = _stable))
            #if (_stable && _stable == prev_status)
            #    global_count++
            #else
            #    global_count = 0
            #    prev_status = null

            #((global_count == 20) && (
            #    global_count = 0
            #    prev_status = null
            #    _is_auto_reset = !!$("#auto-reset").attr("checked")
            #    _view = @
            #    (_is_auto_reset && _view.reset())
            #    _localTime = null
            #    (!_is_auto_reset && $("#auto-run").trigger("click"))
            #))
                        
            _stable


        set: (cellset) ->
            _num = @num
            _Math = Math
            cells = []
            _rnd_ghost = !!$("#rnd_ghost").attr("checked")
            _rule = $("#mode option:selected").html().split("/")
            _dying_const = 0
            if (_rnd_ghost && _rule[2].length and _rule[2] != " ")
                _dying_const = parseInt(_rule[2])
            i = -1
            while (++i < _num)
                _rnd = _Math.random()
                cell_i = null
                cellset.map((set_i, idx) ->
                    _low = 0
                    (idx && (_low = cellset[idx - 1].rate))
                    _high = set_i.rate
                    (((_rnd - _low) * (_rnd - _high) <= 0) && (
                        cell_i = new cell_model[set_i.name]({
                            position: i,
                            dying: _dying_const
                        })
                    ))
                )
                cells.push(cell_i)
            cells
        clear: () ->
            @cells = []
            @
    })

    SCENE
)

