_compact = (array) -> e for e in array when e
_select = (array, f) -> e for e in array when f e
_last = (array) -> array[array.length-1]
_inject = (array, memo, iterator) ->
  for e in array
    memo = iterator.call array, memo, e
  memo
_keys = (obj) -> k for k of obj
_values = (obj) -> v for k, v of obj
_isString = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))

@v15n =
  setKeys: (@keys) -> @aliases = {}
  setValues: (@values) ->
  addKeys: (keys) ->
    for index, key of keys
      if existing = @indexOf key
        @aliases[index] = existing
      else
        @keys[index] = key
    return true
  addValues: (values) ->
    for index, value of values
      @values[index] = value unless index of @aliases
    return true
  indexOf: (key) ->
    for i, k of @keys
      return i if key is k
    return false
  save: (index) ->
    @values[index] = $("[index=#{index}] input").val()
    value = if @values[index].length is 0 then _last(@keys[index].split('.')) else @values[index]
    $.post '/v15n/save', locale: @locale, key: @keys[index], value: @values[index], =>
      @processing.update index, value
    @updateCustom @keys[index], $("[index=#{index}] input").val()
  addCustom: (key) ->
    $.post '/v15n/custom_sadd', page: @page, key: key, =>
      $('.ccontrol input', @panel.body).val('')
      @panel.loadCustom()
  deleteCustom: (key, row) ->
    $.post '/v15n/custom_srem', page: @page, key: key, -> row.remove()
  saveCustom: (key, row) ->
    value = $('input', row).val()
    $.post '/v15n/save', locale: @locale, key: key, value: value
    @updateTranslation key, value
  updateCustom: (key, value) ->
    $('.ctranslations>div>div', @panel.body).each ->
      $(this).nextAll('input').val(value) if $(this).html() is key
  updateTranslation: (key, value) ->
    return unless index = @indexOf key
    @values[index] = value
    $("[index=#{index}] input").val value
    @processing.update index, if @values[index].length is 0 then _last(@keys[index].split('.')) else @values[index] # duplication!
  process: -> @processing.all()
  setBounds: (start, end) -> @processing.setBounds start, end

  processing:
    all: ->
      @setDefaultBounds() unless @tester?
      $('*:not(style,script,#v15n_panel,#v15n_panel *)').each (i, e) =>
        $(e).removeAttr 'v15n_key'
        @forPropertiesOf e, @element
        return true
      return true
    forPropertiesOf: (elem, iterator) ->
      properties = (@property node for node in elem.childNodes when node.nodeType is Node.TEXT_NODE and @test node.data)
      properties = properties.concat (@property attr for attr in elem.attributes when @test attr.nodeValue)
      iterator.call this, elem, prop for prop in properties
      return elem
    property: (obj) ->
      prop = {}
      text = obj instanceof Text
      prop.__defineGetter__ 'value', -> if text then obj.data else obj.nodeValue
      prop.__defineSetter__ 'value', (value) ->
        if text then obj.data = value else obj.nodeValue = value
      return prop
    element: (element, prop) ->
      prop.value.replace @extractor, (match) ->
        index = match.charCodeAt(0)
        key = _compact([$(element).attr('v15n_key')]).concat(index).join('|')
        $(element).attr 'v15n_key', key
        match
    update: (index, value) ->
      indices = [index]
      indices.push alias for alias, indx of v15n.aliases when indx is index
      for indx in indices
        bchar = String.fromCharCode(indx)
        $("[v15n_key*=#{indx}]").each ->
          v15n.processing.forPropertiesOf this, (e, prop) ->
            prop.value = prop.value.replace((new RegExp("#{bchar}.*?#{bchar}", 'g')), "#{bchar}#{value}#{bchar}")

    setBounds: (start, end) ->
      @tester = new RegExp("[#{String.fromCharCode start}-#{String.fromCharCode end}]")
      @extractor = new RegExp("([#{String.fromCharCode start}-#{String.fromCharCode end}]).+?\\1", 'g')
    setDefaultBounds: -> @setBounds 40960, 42124
    test: (str) ->
      return false unless str
      @tester.test str

  panel:
    renderingMethod: 'list'
    render: ->
      @body = $('<div id="v15n_panel"/>').appendTo('body')
      @body.append v15n.panel.html
      $('.locale', @body).html(v15n.locale)
      $('.v15n_menu input', @body).click ->
        v15n.panel.renderingMethod = $(this).val()
        v15n.panel.renderTranslations()
      $('.ccontrol a:first', @body).click =>
        @loadCustom()
        return false
      $('.ccontrol a:last', @body).click ->
        $(this).next().toggle()
        return false
      $('.ccontrol img', @body).click =>
        v15n.addCustom $('.ccontrol input', @body).val()
      @renderTranslations()
      @loadCustom()
      @body.draggable handle: '.v15n_menu>h5' if $.fn.draggable
      @body
    renderTranslations: ->
      $('.translations', @body).children().remove()
      @rendering[@renderingMethod].call v15n
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
          @panel.rendering.item.call this, key, index, $('.translations', @panel.body)
        return @panel
      tree: ->
        renderBlock = (obj, el) =>
          for key, value of obj
            if _isString value
              @panel.rendering.item.call this, key, value, $('div:first', el), false
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
      item: (->
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
          return row
        )()

$.ajaxPrefilter 'json', (options, originalOptions) ->
  if originalOptions.success?
    options.success = (obj) ->
      if obj.v15n?
        v15n.addKeys obj.v15n.keys
        v15n.addValues obj.v15n.values
        delete obj.v15n
      originalOptions.success.apply this, arguments
      v15n.process()
      v15n.panel.renderTranslations()

focusTimeout = no
$("[v15n_key]").live
  mouseover: (e) ->
    index = $(this).attr 'v15n_key'
    index = index.split('|')[0] if /\|/.test index
    index = v15n.aliases[index] if index of v15n.aliases
    focusTimeout = setTimeout ->
      $('.translations .block', v15n.panel.body).hide()
      $("[index=#{index}]", v15n.panel.body).parents(':hidden').show()
      $("[index=#{index}] input", v15n.panel.body).focus()
    , 300
    e.stopPropagation()
  mouseout: ->
    if focusTimeout
      clearTimeout focusTimeout
      focusTimeout = no

@v15n.panel.html = '''
  <div class="v15n_menu">
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