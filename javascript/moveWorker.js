(function() {
  var chkbyNei;

  chkbyNei = function(nei) {
    var bedead, i, nei_i;
    bedead = 0;
    for (i in nei) {
      nei_i = nei[i];
      (nei_i.type === "role" && !nei_i.ghost) && (bedead++);
    }
    return bedead;
  };

  self.onmessage = function(e) {
    var bedead, cell, chk, cond, delay, i, nei, realStable, rule, _data, _len, _stable, _type;
    _data = e.data;
    self.postMessage(_data);
    cell = _data.cell;
    nei = _data.nei;
    rule = _data.rule;
    delay = _data.delay;
    _len = cell.length;
    i = -1;
    realStable = true;
    while (++i < _len) {
      bedead = chkbyNei(nei[i]);
      _type = cell[i].type;
      _stable = true;
      switch (_type) {
        case "empty":
          cond = rule[1];
          chk = cond ? cond.test(bedead) : false;
          chk && (cell[i].type = "role", _stable = false);
          break;
        default:
          if (delay && cell[i].lifecycle < cell[i].delay) {
            cell[i].lifecycle++;
          } else {
            cell[i].lifecycle = 0;
            cond = rule[0];
            if (!cell.ghost) {
              chk = cond ? cond.test(bedead) : false;
              !chk && rule[2] > 0 && (_stable = false);
            }
            (!_stable || cell[i].ghost) && rule[2] && (cell[i].ghost++, _stable = false);
            ((!chk && !rule[2]) || (rule[2] > 0 && cell[i].ghost >= rule[2])) && (cell[i].type = "empty", _stable = false);
          }
      }
      !_stable && (realStable = false);
    }
    return self.postMessage({
      cell: cell,
      stable: realStable,
      id: _data.id
    });
  };

}).call(this);
