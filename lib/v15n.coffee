_compact = (array) -> e for e in array when e
_select = (array, f) -> e for e in array when f e
_last = (array) -> array[array.length-1]
_inject = (array, memo, iterator) ->
  for e in array
    memo = iterator.call array, memo, e
  memo
_keys = (obj) -> k for k of obj
_isString = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))

@v15n =
  process: ->
    @setDefaultBounds() unless @tester?
    $('*:not(.v15n_processed):not(#v15n_panel)').each ->
      $(this).addClass 'v15n_processed'
      for node in @childNodes
        if node.nodeType is Node.TEXT_NODE and v15n.test node.data
          v15n.processElement this, node.data
      for attribute in @attributes
        v15n.processElement this, attribute.nodeValue if v15n.test attribute.nodeValue
      return true
    return true
  processElement: (element, text) ->
    text.replace @extractor, (match) ->
      keyCode = match.charCodeAt(0)
      key = _compact([$(element).attr('v15n_key')]).concat(keyCode).join('|')
      $(element).attr 'v15n_key', key
      match
  setKeys: (@keys) ->
  setValues: (@values) ->
  addKeys: (keys) -> $.extend @keys, keys
  addValues: (values) -> $.extend @values, values
  panel:
    renderingMethod: 'list'
    render: ->
      @body = $('<div id="v15n_panel"/>').appendTo('body')
      @body.append '''
        <div class="menu">
          <h5>Current Locale: <span class="locale">?</span></h5>
          <div class="control">
            <span>View as:</span>
            <input type="radio" name="v15n_rendering_method" id="v15n_rendering_method_list" value="list" checked="checked"/>
            <label for="v15n_rendering_method_list">List</label>
            <input type="radio" name="v15n_rendering_method" id="v15n_rendering_method_tree" value="tree"/>
            <label for="v15n_rendering_method_tree">Tree</label>
          </div>
        </div>
        <div class="translations"/>
        <div class="custom-translations">
          <div class="ctranslations"/>
          <div class="ccontrol">
            <a href="#">Reload</a> |
            <a href="#">Add...</a>
            <div style="float: right; display: none;">
              <img src="/images/v15n_save.png"style="cursor: pointer; float: right"/>
              <input type="text" name="v15n_custom_key" id="v15n_custom_key" style="width:250px; float: right"/>
            </div>
            <div class="clear" />
          </div>
        </div>
      '''
      $('.locale', @body).html(v15n.locale)
      $('.menu input', @body).click ->
        v15n.panel.renderingMethod = $(this).val()
        v15n.panel.renderTranslations()
      $('.ccontrol a:first', @body).click =>
        @loadCustom()
        return false
      $('.ccontrol a:last', @body).click ->
        $(this).next().toggle()
        return false
      $('.ccontrol img', @body).click =>
        $.post '/v15n/custom_sadd', page: v15n.page, key: $('.ccontrol input', @body).val(), =>
          $('.ccontrol input', @body).val('')
          @loadCustom()
      @renderTranslations()
      @loadCustom()
      @body.draggable handle: '.menu>h5' if $.fn.draggable
      @body
    renderTranslations: ->
      $('.translations', @body).children().remove()
      @rendering[@renderingMethod].call v15n
    renderItem: (->
      odd = yes
      cycle = ->
        odd = not odd
        if odd then 'odd' else 'even'
      (key, index, canvas, full = true) ->
        keyName = if full then key else _last(key.split('.'))
        row = $("<div index='#{index}' class='item #{cycle()}'><div class='key'>#{keyName}</div></div>").appendTo(canvas)
        $('<div style="float: right;"><img src="/images/v15n_save.png" style="cursor: pointer"/></div>').appendTo(row).click => @save index
        $("<input type='text' value='#{@values[index]}' style='float: right'/>").appendTo(row)
        $('<div class="clear"/>').appendTo(row)
        focusTimeout = no
        $("[v15n_key*=#{index}]").bind
          mouseover: (e) =>
            focusTimeout = setTimeout =>
              $('.translations .block', @panel.body).hide()
              $("[index=#{index}]").parents(':hidden').show()# if $("[index=#{index}]").is ':hidden'
              $("[index=#{index}] input").focus()
            , 200
            e.stopPropagation()
          mouseout: ->
            if focusTimeout
              clearTimeout focusTimeout
              focusTimeout = no
        return row
      )()
    loadCustom: ->
      $('.ctranslations', @body).html('Loading...')
      $.get "/v15n/custom?page=#{v15n.page}", (custom) =>
        v15n.custom = custom
        $('.ctranslations', @body).html('')
        @rendering.custom.call v15n
      , 'json'
    rendering:
      list: ->
        for index, key of @keys
          @panel.renderItem.call this, key, index, $('.translations', @panel.body)
        return @panel
      tree: ->
        renderBlock = (obj, el) =>
          for key, value of obj
            if _isString value
              @panel.renderItem.call this, key, value, $('div:first', el), false
            else
              block = $("<div><a href='#' style='font-weight: bold'>#{key}</a><div class='block' style='display: none; margin-left: 8px;'></div></div>").appendTo($('div:first', el))
              $('a', block).click ->
                $(this).next().toggle()
                return false
              renderBlock value, block
          return true
        sortObj = (obj) ->
          sorted = {}
          keys = _select(_keys(obj), (k) -> not _isString(obj[k])).sort().concat _select(_keys(obj), (k) -> _isString(obj[k])).sort()
          for key in keys
            sorted[key] = if _isString obj[key] then obj[key] else sortObj(obj[key])
          return sorted
        tree = {}
        for index, key of @keys
          parts = key.split('.')
          obj = _inject(parts[0..parts.length-2], tree, (obj, k) -> if obj[k] then obj[k] else obj[k] = {})
          obj[key] = index
        renderBlock sortObj(tree), $('.translations', @body).append('<div class="block"/>')
        return @panel
      custom: ->
        for key, value of @custom
          row = $("<div><div style='float: left; width: 185px;'>#{key}</div></div>").appendTo($('.ctranslations', @panel.body))
          $('<div style="float: right;"><img src="/images/v15n_save.png" style="cursor: pointer"/></div>').appendTo(row).click => @saveCustom key, row
          $('<div style="float: right;"><img src="/images/v15n_delete.png" style="cursor: pointer"/></div>').appendTo(row).click => @deleteCustom key, row
          $("<input type='text' value='#{value}' style='float: right'/>").appendTo(row)
          $('<div class="clear"/>').appendTo(row)
        return true
  save: (index) ->
    @values[index] = $("[index=#{index}] input").val()
    value = if @values[index].length is 0 then _last(@keys[index].split('.')) else @values[index]
    bchar = String.fromCharCode(index)
    $.post '/v15n/save', locale: @locale, key: @keys[index], value: @values[index], ->
      bchar = String.fromCharCode(index)
      $("[v15n_key*=#{index}]").each ->
        $(this).html($(this).html().replace((new RegExp("#{bchar}.*?#{bchar}", 'g')), "#{bchar}#{value}#{bchar}"))
  saveCustom: (key, row) ->
    value = $('input', row).val()
    $.post '/v15n/save', locale: @locale, key: key, value: value
  deleteCustom: (key, row) ->
    $.post '/v15n/custom_srem', page: @page, key: key, -> row.remove()
  test: (str) ->
    return false unless str
    @tester.test str
  extract: (text) -> text.match
  setBounds: (start, end) ->
    @tester = new RegExp("[#{String.fromCharCode start}-#{String.fromCharCode end}]")
    @extractor = new RegExp("([#{String.fromCharCode start}-#{String.fromCharCode end}]).+?\\1", 'g')
  setDefaultBounds: -> @setBounds 40960, 42124
