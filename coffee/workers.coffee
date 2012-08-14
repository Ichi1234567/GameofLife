chkbyNei = (nei) ->
    bedead = 0
    for i, nei_i of nei
    #nei.forEach(nei_i) ->
        ((nei_i.type == "role" && !nei_i.ghost) && (
            bedead++
        ))
    bedead

ACTS = {
    getDelta : (_data) ->
        cell = _data.cell
        nei = _data.nei
        rule = _data.rule
        delay = _data.delay

        _len = cell.length
        i = -1
        realStable = true
        while (++i < _len)
            bedead = chkbyNei(nei[i])
            _type = cell[i].type
            _stable = true
            switch (_type)
                when ("empty")
                    cond = rule[1]
                    chk = if (cond) then (cond.test(bedead)) else (false)

                    ((chk) && (
                        cell[i].type = "role"
                        _stable = false
                    ))
                else
                    if (delay && cell[i].lifecycle < cell[i].delay)
                        cell[i].lifecycle++
                    else
                        cell[i].lifecycle = 0
                        cond = rule[0]
                        if (!cell.ghost)
                            chk = if (cond) then (cond.test(bedead)) else (false)
                            (!chk && rule[2] > 0 && (
                                _stable = false
                            ))
                        ((!_stable || cell[i].ghost) && (
                            cell[i].ghost++
                            _stable = false
                        ))
                        (((!chk && !rule[2]) ||
                        (rule[2] > 0 && cell[i].ghost >= rule[2])) && (
                            cell[i].type = "empty"
                            _stable = false
                        ))
            (!_stable && (realStable = false))
        {
            act: "show",
            stable: realStable,
            cell: cell,
            id: _data.id
        }
    default: (data) ->
        data
}




self.onmessage = (e) ->
    data = e.data
    act = data.act
    result = ACTS[act](data)
    self.postMessage(result)
