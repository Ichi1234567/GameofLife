(function() {

  define(["color"], function(COLOR) {
    var _Doc, _Math;
    console.log("display");
    _Math = Math;
    _Doc = document;
    $.fn.showCanvas = function(params) {
      var canvas, ctx, data, g_num, h, num, w;
      if (!params) return;
      w = params.w ? params.w : 400.;
      h = params.h ? params.h : 400.;
      num = params.num;
      g_num = [w / num, h / num];
      data = params.data;
      canvas = _Doc.createElement("canvas");
      canvas.width = w;
      canvas.height = h;
      ctx = canvas.getContext("2d");
      ctx.lineCap = "round";
      ctx.lineJoin = "miterLimit";
      ctx.fillStyle = "#" + COLOR.empty[0];
      ctx.clearRect(0, 0, w, h);
      ctx.beginPath();
      ctx.fillRect(0, 0, w, h);
      data.forEach(function(data_i) {
        var c_i, ghost, pos_i, r_i, type_i;
        type_i = data_i.type;
        if (type_i !== "empty") {
          pos_i = data_i.position;
          ghost = data_i.ghost;
          r_i = _Math.floor(pos_i / num);
          c_i = pos_i % num;
          ctx.fillStyle = "#" + COLOR[type_i][ghost];
          return ctx.fillRect(g_num[0] * r_i, g_num[1] * c_i, g_num[0], g_num[1]);
        }
      });
      ctx.closePath();
      $(canvas).addClass("panel");
      $(this).append(canvas);
      return this;
    };
    return $.fn.upCanvas = function(cells, params) {
      var canvas, ctx, g_num, h, num, w;
      if (!cells || !params) return;
      canvas = $(this).find("canvas").get(0);
      ctx = canvas.getContext("2d");
      w = canvas.width;
      h = canvas.height;
      num = params.num;
      g_num = [w / num, h / num];
      ctx.beginPath();
      cells.forEach(function(data_i) {
        var c_i, ghost, pos_i, r_i, type_i;
        type_i = data_i.type;
        pos_i = data_i.position;
        ghost = data_i.ghost;
        r_i = _Math.floor(pos_i / num);
        c_i = pos_i % num;
        ctx.fillStyle = "#" + COLOR[type_i][ghost];
        ctx.fillRect(g_num[0] * r_i, g_num[1] * c_i, g_num[0], g_num[1]);
        return data_i.visited = false;
      });
      ctx.closePath();
      return this;
    };
  });

}).call(this);
