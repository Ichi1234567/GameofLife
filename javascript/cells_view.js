(function() {

  define(["basic_cell", "role_cell", "food_cell", "enemy_cell", "display", "rule"], function(BASIC, ROLE, FOOD, ENEMY, DISPLAY, RULE) {
    var ACTS, Fps, Frames, LastTime, ROUTINES, SCENE, UpdateTime, cell_model, global_count, global_timmer, prev_status, _Math;
    console.log("cells_view");
    _Math = Math;
    cell_model = {
      empty: BASIC,
      role: ROLE,
      food: FOOD,
      enemy: ENEMY
    };
    global_timmer = null;
    global_count = 0;
    prev_status = null;
    Frames = 0;
    UpdateTime = 1000;
    LastTime = new Date();
    Fps = 0;
    window.requestAnimationFrame = (function() {
      return window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(callback, element) {
        return window.setTimeout(callback, 1000 / 60);
      };
    })();
    window.cancelRequestAnimFrame = (function() {
      return window.cancelAnimationFrame || window.webkitCancelRequestAnimationFrame || window.mozCancelRequestAnimationFrame || window.oCancelRequestAnimationFrame || window.msCancelRequestAnimationFrame || clearTimeout;
    })();
    ROUTINES = {
      evalSet: function(num, ghost_num, opts) {
        var _avgSB, _base, _type;
        ghost_num = ghost_num ? ghost_num : 0.;
        _base = opts.base ? opts.base : 0.27;
        _type = opts.type ? opts.type : "role";
        _avgSB = opts.avgSB ? opts.avgSB : 0.;
        _base *= _Math.cos(_avgSB / 9);
        _base *= 1 + ghost_num / 40;
        return _Math.round(num * _base);
      },
      sortSets: function(sets, opts) {
        var count, _empty, _num;
        _num = opts.num;
        _empty = _num;
        sets.forEach(function(elm, idx) {
          return _empty -= elm.num;
        });
        sets.push({
          name: "empty",
          num: _empty
        });
        sets = sets.sort(function(a, b) {
          return a.num - b.num;
        });
        count = 0;
        sets = sets.map(function(set_i) {
          count += set_i.num;
          set_i.rate = count / _num;
          return set_i;
        });
        return sets;
      },
      generateSets: function(totalNum, opts) {
        var sets, tmp_sets, _avgSB, _base, _ghost, _types;
        opts = opts ? opts : {};
        _types = opts.types ? opts.types : ["role"];
        _ghost = opts.ghost ? opts.ghost : 0.;
        _base = opts.base ? opts.base : 0.27;
        _avgSB = opts.avgSB ? opts.avgSB : 0.;
        tmp_sets = _types.map(function(type_i) {
          var num;
          num = ROUTINES.evalSet(totalNum, _ghost, {
            base: _base,
            type: type_i,
            avgSB: _avgSB
          });
          return {
            name: type_i,
            num: num
          };
        });
        sets = ROUTINES.sortSets(tmp_sets, {
          num: totalNum
        });
        return sets;
      }
    };
    ACTS = {
      "default": function(view, data) {
        view.state = data.cells;
        return view;
      },
      show: function(view, data) {
        var cell, cell_i, i, posi, stable, up_cells, _len, _size, _types;
        stable = data.stable;
        cell = data.cell;
        _len = cell.length;
        i = -1;
        up_cells = [];
        _size = view.size;
        _types = {
          empty: BASIC,
          role: ROLE,
          food: FOOD,
          enemy: ENEMY
        };
        while (++i < _len) {
          cell_i = cell[i];
          up_cells.push(cell_i);
          posi = cell_i.position;
          view.cells[posi].type !== cell_i.type && (view.cells[posi] = new _types[cell_i.type]({
            position: posi
          }));
          view.cells[posi].type === cell_i.type && (view.cells[posi].ghost = cell_i.ghost, view.cells[posi].lifecycle = cell_i.lifecycle);
        }
        return !stable && $(".plant").each(function(idx, elm) {
          return $(elm).upCanvas(up_cells, {
            num: _size
          });
        });
      }
    };
    SCENE = Backbone.View.extend({
      initialize: function(params) {
        var act_i, i, _h, _num, _this, _w, _workers;
        params = params ? params : {};
        this.num = params.num ? params.num : 64.;
        _num = this.num;
        this.size = _Math.ceil(_Math.sqrt(_num));
        this.w = params.w ? params.w : 300.;
        this.h = params.h ? params.h : 300.;
        _w = this.w;
        _h = this.h;
        this.current = 0;
        _this = this;
        for (i in ACTS) {
          act_i = ACTS[i];
          ACTS[i] = (function(view, act_i) {
            return function(params) {
              return act_i(view, params);
            };
          })(_this, act_i);
        }
        _workers = new Worker("javascript/workers.js");
        _workers.addEventListener("message", function(e) {
          var act, data;
          data = e.data;
          act = data.act;
          return ACTS[act](data);
        }, false);
        this.workers = _workers;
        $(".plant").eq(1).css("top", -(_h + 7));
        this.chk_opts();
        this.reset("init");
        return this;
      },
      "events": {
        "click #reset": "click_reset",
        "click #next": "next",
        "click #auto-run": "auto_run",
        "change #mode": "chg_opts",
        "change #rnd_ghost": "chg_opts",
        "change #chk-delay": "chg_opts"
      },
      render: function() {
        return this;
      },
      remove: function() {
        return this;
      },
      auto_run: function(e, status) {
        var curr_time, dt, _$target, _fps, _running, _stable, _view;
        _$target = $(e.target);
        if (!status) {
          _running = !!(_$target.attr("class"));
          _$target.toggleClass("running");
        }
        _view = this;
        if (_running && !status) {
          _stable = true;
        } else {
          _$target.html("stop");
          _stable = false;
          global_timmer && cancelRequestAnimFrame(global_timmer);
          global_timmer = requestAnimationFrame(function() {
            _view.auto_run(e, true);
            return _stable = _view.next();
          });
        }
        if (_stable) {
          _$target.html("auto-run");
          cancelRequestAnimFrame(global_timmer);
          global_timmer = null;
        } else {
          curr_time = new Date();
          Frames++;
          dt = curr_time.getTime() - LastTime.getTime();
          if (dt > UpdateTime) {
            _fps = _Math.round((Frames / dt) * UpdateTime);
            Frames = 0;
            LastTime = curr_time;
            $("#fps").html(_fps);
          }
        }
        return this;
      },
      chg_opts: function(e) {
        var _$target, _is_auto_run, _rule;
        _$target = $(e.target);
        _rule = $("#mode option:selected").html().split("/");
        _is_auto_run = $("#auto-run").attr("class") === "running";
        switch (true) {
          case _$target.is("#mode"):
            _is_auto_run && $("#auto-run").trigger("click");
            this.chk_opts();
            this.reset();
            break;
          case _$target.is("#chk-delay"):
            this.chk_opts();
            break;
          case _rule[2].length && _rule[2] !== " ":
            this.chk_opts();
            !_is_auto_run && this.reset();
        }
        return this;
      },
      click_reset: function() {
        var _is_auto_run;
        _is_auto_run = $("#auto-run").attr("class") === "running";
        _is_auto_run && $("#auto-run").trigger("click");
        return this.reset();
      },
      chk_opts: function() {
        var i, sum, _chk_delay, _len, _rule;
        _chk_delay = !!$("#chk-delay").attr("checked");
        _rule = $("#mode option:selected").html().split("/");
        sum = 0;
        _len = 0;
        i = 2;
        while (--i > -1) {
          (function(i) {
            _rule[i].split("").forEach(function(val) {
              var _val;
              _val = parseInt(val);
              return !isNaN(_val) && (sum += _val);
            });
            return _len += _rule[i].length;
          })(i);
        }
        this.cellSet = ROUTINES.generateSets(this.num, {
          ghost: parseInt(_rule[2]),
          base: _chk_delay ? 0.2 : 0.27,
          avgSB: (_rule[0].length + _rule[1].length) / 2
        });
        return this;
      },
      reset: function(init) {
        var _cells, _current, _h, _num, _size, _w;
        global_count = 0;
        this.cells = this.set(this.cellSet);
        _num = this.num;
        _cells = this.cells;
        _w = this.w;
        _h = this.h;
        _size = this.size;
        _current = this.current;
        this.workers.postMessage({
          cells: _cells,
          act: "default"
        });
        $(".plant").each(function(idx, elm) {
          var $elm, _chk;
          _chk = idx - _current;
          $elm = $(elm);
          $(elm).html("").showCanvas({
            w: _w,
            h: _h,
            num: _size,
            data: _cells
          });
          $elm.css("visibility") === "visible" && $elm.css("hidden");
          $elm.css("visibility") !== "visible" && $elm.css("visible");
          return true;
        });
        this.current = (_current + 1) % 2;
        return this;
      },
      next: function() {
        var c_size, canvas, cell_i, ctx, g_num, get_nei, i, mode, _args, _cells, _chk_delay, _current, _iden, _num, _stable, _state, _w_cell, _w_nei, _workers;
        _current = this.current;
        _cells = this.cells;
        _num = this.num;
        _state = this.state;
        _stable = true;
        mode = $("#mode option:selected").val();
        _chk_delay = !!$("#chk-delay").attr("checked");
        c_size = this.size;
        canvas = $("canvas").eq(_current).get(0);
        ctx = canvas.getContext("2d");
        g_num = [this.w / c_size, this.h / c_size];
        get_nei = function(total_cells, thisCell, state, opts) {
          var base_pos, delta, position, result, up_cells;
          position = thisCell.position;
          c_size = opts.c_size;
          ctx = opts.ctx;
          g_num = opts.g_num;
          result = {
            stable: true
          };
          up_cells = [];
          base_pos = [(position % c_size) * g_num[0] + g_num[0] / 2, _Math.floor(position / c_size) * g_num[1] + g_num[1] / 2];
          delta = [[-1, -1, -c_size - 1], [0, -1, -c_size], [1, -1, -c_size + 1], [-1, 0, -1], [1, 0, 1], [-1, 1, c_size - 1], [0, 1, c_size], [1, 1, c_size + 1]];
          delta.forEach(function(delta_i, idx) {
            var cell_i, pos_i;
            pos_i = [base_pos[0] + delta_i[0] * g_num[0], base_pos[1] + delta_i[1] * g_num[1]];
            cell_i = total_cells[position + delta_i[2]];
            return ctx.getImageData(pos_i[0], pos_i[1], 1, 1).data[3] && !cell_i.visited && (up_cells.push(cell_i));
          });
          return up_cells;
        };
        _args = {
          empty: BASIC,
          role: ROLE,
          food: FOOD,
          enemy: ENEMY,
          delay: _chk_delay,
          c_size: c_size,
          ctx: ctx,
          g_num: g_num
        };
        i = -1;
        _workers = this.workers;
        _w_cell = [];
        _w_nei = [];
        _iden = 100;
        while (++i < _num) {
          if (!(i % _iden)) {
            _w_cell = [];
            _w_nei = [];
          }
          cell_i = _cells[i];
          _w_cell.push(cell_i);
          _w_nei.push(get_nei(_cells, cell_i, _cells, _args));
          !((i + 1) % _iden) && _workers.postMessage({
            act: "getDelta",
            id: i,
            cell: _w_cell,
            nei: _w_nei,
            rule: RULE[mode],
            delay: _chk_delay
          });
        }
        return _stable;
      },
      set: function(cellset) {
        var cell_i, cells, i, _dying_const, _num, _rnd, _rnd_ghost, _rule;
        _num = this.num;
        _Math = Math;
        cells = [];
        _rnd_ghost = !!$("#rnd_ghost").attr("checked");
        _rule = $("#mode option:selected").html().split("/");
        _dying_const = 0;
        if (_rnd_ghost && _rule[2].length && _rule[2] !== " ") {
          _dying_const = parseInt(_rule[2]);
        }
        i = -1;
        while (++i < _num) {
          _rnd = _Math.random();
          cell_i = null;
          cellset.map(function(set_i, idx) {
            var _high, _low;
            _low = 0;
            idx && (_low = cellset[idx - 1].rate);
            _high = set_i.rate;
            return ((_rnd - _low) * (_rnd - _high) <= 0) && (cell_i = new cell_model[set_i.name]({
              position: i,
              dying: _dying_const
            }));
          });
          cells.push(cell_i);
        }
        return cells;
      },
      clear: function() {
        this.cells = [];
        return this;
      }
    });
    return SCENE;
  });

}).call(this);
