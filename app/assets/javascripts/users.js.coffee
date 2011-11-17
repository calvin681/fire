$ = jQuery

$.fn.extend
  timeline: (options) ->
    defaultOptions =
      initialMonthHeight: 50
      minMonthHeight: 5
      tipMargin: 5
      tipHeight: 13
      verticalMargin: 10
      minCollapsibleHeight: 120
      collapsedHeight: 70
      timelineWidth: 3
    
    options = $.extend defaultOptions, options
    
    init = ($context, monthHeight) ->
      props =
        left:
          offset: 0
          episodes: []
          maxHeight: 0
        right:
          offset: 0
          episodes: []
          maxHeight: 0
        shrinkage: 0
        episodes: []
        endDateNumber: parseInt($context.attr("data-end-date-number"))
        monthHeight: monthHeight
        width: $context.width()
        
      $context.find("> .card[data-start]").each () ->
        processEpisode($(@), props)
      
      if 0 < props.shrinkage < 1
        newMonthHeight = Math.max(Math.ceil(monthHeight * props.shrinkage), options.minMonthHeight)
        if options.minMonthHeight <= newMonthHeight < monthHeight
          init($context, newMonthHeight)
          return
      
      $timeline = $context.find(".timeline")
      generateTimeline($timeline, props)
      
      totalHeight = Math.max(props.left.maxHeight, props.right.maxHeight)
      props.left.maxHeight = props.left.offset = props.right.maxHeight = props.right.offset = totalHeight
      $context.find("> .card:not([data-start])").each () ->
        processEpisode($(@), props)
        return
      
      newTotalHeight = Math.max(props.left.maxHeight, props.right.maxHeight)
      
      $collapsedLine = $("<div class='collapsed'></div>").css
        top: totalHeight
        height: newTotalHeight - totalHeight
        width: options.timelineWidth
      $timeline.prepend($collapsedLine)
      totalHeight = newTotalHeight
      
      setTimeout () ->
        $context.height(totalHeight).css
          overflow: "visible"
        moveEpisodes($context)
      , 400
      setTimeout () ->
        $timeline.hide().css
          overflow: 'visible'
        $timeline.height(totalHeight)
        $timeline.fadeIn(1000)
      , 1400
      
    processEpisode = ($episode, props) ->
      $body = $episode.find(".body").hide()
      minHeight = $episode.outerHeight()
      $body.show()
      $episode.css(left: (props.width - $episode.outerWidth()) / 2)
      
      startDateOffset = parseInt($episode.attr("data-start"))
      endDateOffset = parseInt($episode.attr("data-end"))
      pos =
        minHeight: minHeight
        height: $episode.outerHeight()
        fullHeight: $episode.outerHeight()
        verticalPadding: $episode.outerHeight() - $episode.height()
        timelineStart: startDateOffset * props.monthHeight
        timelineEnd: endDateOffset * props.monthHeight
        minOverlap: options.tipMargin + options.tipHeight
      
      if props.right.offset < props.left.offset
        sideProps = props.right
        pos.left = props.width - $episode.outerWidth()
      else
        sideProps = props.left
        pos.left = 0
      
      if !isNaN(startDateOffset)
        pos.minOverlap = Math.min(props.monthHeight * (startDateOffset - endDateOffset), pos.minOverlap)
        minOffset = sideProps.episodes.reduce (sum, e) ->
          sum += (e.data("pos").height + options.verticalMargin)
        , 0
        shrinkage = (minOffset + Math.min(pos.minOverlap,
                     options.minMonthHeight * (startDateOffset - endDateOffset))) / pos.timelineStart
      
        if pos.timelineStart < sideProps.offset + pos.minOverlap
          props.shrinkage = 1
          diff = sideProps.offset + pos.minOverlap - pos.timelineStart
          pos.top = pos.timelineStart - pos.minOverlap
          if shiftEpisode(diff, sideProps.episodes, sideProps.episodes.length - 1)
            sideProps.offset = pos.top + pos.height + options.verticalMargin
        else
          props.shrinkage = Math.max(shrinkage, props.shrinkage)
          pos.top = Math.max(pos.timelineEnd - pos.height + pos.minOverlap, sideProps.offset)
      else
        pos.top = sideProps.offset
        pos.timelineStart = 0
      
      $episode.data("pos", pos)
      sideProps.episodes.push($episode)
      sideProps.offset = Math.max(pos.top + pos.height + options.verticalMargin, sideProps.offset)
      sideProps.maxHeight = Math.max(sideProps.offset, pos.timelineStart)
      props.episodes.push($episode)
      
      
    moveEpisodes = ($context) ->
      $context.find("> .card").each () ->
        $episode = $(@)
        pos = $episode.data("pos")
        if pos?
          $episode.animate
            top: pos.top
            left: pos.left
            height: pos.height - pos.verticalPadding, 1000
        return
    
    shiftEpisode = (diff, episodes, index) ->
      return false if index < 0
      
      $episode = episodes[index]
      pos = $episode.data("pos")
      
      maxSlack = pos.top + pos.height - (pos.timelineEnd + pos.minOverlap)
      slack = Math.min(pos.height - pos.minHeight, maxSlack)
      if diff <= slack
        pos.height = pos.height - diff
        return true
      else if diff <= maxSlack && shiftEpisode(diff - slack, episodes, index - 1)
        pos.top = pos.top - (diff - slack)
        pos.height = pos.minHeight
        return true
      
      return false
      
    generateTimeline = ($timeline, props) ->
      return if props.episodes.length is 0
      
      timelineLeft = Math.floor((props.width - options.timelineWidth) / 2)
      $timeline.data("left", timelineLeft).css
        left: timelineLeft
        width: options.timelineWidth
      $timeline.find(".extent").width(options.timelineWidth)
      offset = 0
      collapse = 0
      currentEnd = 0
      for $episode in props.episodes
        pos = $episode.data("pos")
        pos.top -= collapse
        pos.timelineStart -= collapse
        pos.timelineEnd -= collapse
        gap = Math.min(pos.top, pos.timelineEnd) - offset
        if gap > options.minCollapsibleHeight
          insertYearLabels($timeline, currentEnd, offset + options.verticalMargin, collapse, props)
          additionalCollapse = gap - options.collapsedHeight - 2 * options.verticalMargin
          collapse += additionalCollapse
          pos.top -= additionalCollapse
          pos.timelineStart -= additionalCollapse
          pos.timelineEnd -= additionalCollapse
          $collapsedLine = $("<div class='collapsed'></div>").css
            top: offset + options.verticalMargin
            height: options.collapsedHeight
            width: options.timelineWidth
          $timeline.prepend($collapsedLine)

          currentEnd = offset + options.verticalMargin + options.collapsedHeight
        offset = Math.max(pos.top + pos.height, pos.timelineStart, offset)
        generateDuration($episode, $timeline)
        
      insertYearLabels($timeline, currentEnd, offset, collapse, props)
      props.left.maxHeight -= collapse
      props.right.maxHeight -= collapse
      
    nextYearStop = (offset, collapse, props) ->
      endMonth = props.endDateNumber % 12
      yearHeight = 12 * props.monthHeight
      offsetInverse = offset + collapse + yearHeight - endMonth * props.monthHeight
      year = Math.floor(props.endDateNumber / 12) - Math.floor(offsetInverse / yearHeight)
      pos = offset + 12 * props.monthHeight - (offsetInverse % yearHeight)
      return [pos, year]
    
    insertYearLabels = ($timeline, end, start, collapse, props) ->
      [pos, year] = nextYearStop(end, collapse, props)
      while pos <= start
        $label = $("<div class='year'>"+year+"</div>").appendTo($timeline)
        $label.css
          left: - Math.floor(($label.outerWidth() - options.timelineWidth) / 2)
          top: pos - Math.floor($label.outerHeight() / 2)
        [pos, year] = nextYearStop(pos + 1, collapse, props)
    
    generateDuration = ($episode, $timeline) ->
      pos = $episode.data("pos")
      height = pos.timelineStart - pos.timelineEnd
      borderWidth = Math.ceil(($episode.outerWidth() - $episode.innerWidth()) / 2)
      $duration = $("<div class='timeline-duration'></div>").appendTo($timeline).css
        top: pos.timelineEnd
      $episode.data("duration", $duration)
      side = "left"
      css =
        width: $timeline.data("left") - $episode.outerWidth() + borderWidth
      if pos.left isnt 0
        side = "right"
        css.width = pos.left - ($timeline.data("left") + options.timelineWidth) + borderWidth
      css[side] = -css.width
      $duration.css(css)
      # if height >= options.tipHeight
      #   $("<div class='segment top-6 "+side+"'></div>").appendTo($duration)
      #   $("<div class='segment middle "+side+"'></div>").appendTo($duration).css
      #     height: height - (6 * 2)
      #   $("<div class='segment bottom-6 "+side+"'></div>").appendTo($duration)
      # else 
      if height >= 9
        $("<div class='segment top-4 "+side+"'></div>").appendTo($duration)
        $("<div class='segment middle "+side+"'></div>").appendTo($duration).css
          height: height - (4 * 2)
        $("<div class='segment bottom-4 "+side+"'></div>").appendTo($duration)
      else
        $("<div class='segment top-2 "+side+"'></div>").appendTo($duration)
        $("<div class='segment middle "+side+"'></div>").appendTo($duration).css
          height: height - (2 * 2)
        $("<div class='segment bottom-2 "+side+"'></div>").appendTo($duration)
      
      tipTop = Math.max(pos.timelineEnd, pos.top)
      overlap = Math.min(pos.timelineStart, pos.top + pos.height) - tipTop
      tip = $("<div class='tip "+side+"'><div class='link'></div></div>").appendTo($duration);
      
      if overlap >= options.tipMargin + options.tipHeight
        tip.css
          top: tipTop - pos.timelineEnd + Math.min(Math.max(options.tipMargin - (pos.timelineEnd - pos.top), 0), 5)
      else
        tipTop = tipTop - Math.ceil((options.tipHeight - overlap) / 2)
        if tipTop < pos.top + options.tipMargin
          tip.addClass("top").css
            top: Math.floor(overlap / 2) - 1
        else if tipTop + options.tipHeight > pos.top + pos.height - options.tipMargin
          tip.addClass("bottom").css
            bottom: Math.floor(overlap / 2) - 1
        else
          tip.css
            top: tipTop - pos.timelineEnd
      setupHover($episode, $duration)
    
    setupHover = ($episode, $duration) ->
      timeoutId = null
      $episode.hover(() ->
        if not timeoutId?
          timeoutId = setTimeout () ->
            $episode.addClass("hover")
            $duration.addClass("hover")
            pos = $episode.data("pos")
            if pos.height isnt pos.fullHeight
              $episode.animate
                height: pos.fullHeight - pos.verticalPadding
          , 700
      , () ->
        clearTimeout(timeoutId) if timeoutId?
        timeoutId = null
        $episode.removeClass("hover")
        $duration.removeClass("hover")
        pos = $episode.data("pos")
        if pos.height isnt pos.fullHeight
          $episode.css
            height: pos.height - pos.verticalPadding
      )
      
    return @each () ->
      $context = $(this)
      init($context, options.initialMonthHeight)
      return


$ () ->
  $(".timeline-container").timeline()
