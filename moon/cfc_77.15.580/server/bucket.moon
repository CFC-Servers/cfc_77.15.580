import CurTime from _G
import TickCount from engine
import floor from math

tickInterval = engine.TickInterval!
tickRate = 1 / tickInterval

class Section580.Bucket
    new: (@max, @interval=tickRate, @amount=1) =>
        @count = @max
        @lastUpdate = TickCount!

    _updateCount: =>
        if @count < @max
            sinceLast = TickCount! - @lastUpdate
            filledSinceLast = ( floor sinceLast / @interval ) * @amount

            @count += filledSinceLast
            if @count > @max
                @count = @max

        @lastUpdate = TickCount!

    Send: =>
        @_updateCount!
        return false unless @count > @amount

        @count -= @amount
        return true
