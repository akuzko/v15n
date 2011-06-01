(function() {
  var focusTimeout, _compact, _inject, _isString, _keys, _last, _select, _values;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _compact = function(array) {
    var e, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      e = array[_i];
      if (e) {
        _results.push(e);
      }
    }
    return _results;
  };
  _select = function(array, f) {
    var e, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      e = array[_i];
      if (f(e)) {
        _results.push(e);
      }
    }
    return _results;
  };
  _last = function(array) {
    return array[array.length - 1];
  };
  _inject = function(array, memo, iterator) {
    var e, _i, _len;
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      e = array[_i];
      memo = iterator.call(array, memo, e);
    }
    return memo;
  };
  _keys = function(obj) {
    var k, _results;
    _results = [];
    for (k in obj) {
      _results.push(k);
    }
    return _results;
  };
  _values = function(obj) {
    var k, v, _results;
    _results = [];
    for (k in obj) {
      v = obj[k];
      _results.push(v);
    }
    return _results;
  };
  _isString = function(obj) {
    return !!(obj === '' || (obj && obj.charCodeAt && obj.substr));
  };
  this.v15n = {
    setKeys: function(keys) {
      this.keys = keys;
      return this.aliases = {};
    },
    setValues: function(values) {
      this.values = values;
    },
    addKeys: function(keys) {
      var existing, index, key;
      for (index in keys) {
        key = keys[index];
        if (existing = this.indexOf(key)) {
          this.aliases[index] = existing;
        } else {
          this.keys[index] = key;
        }
      }
      return true;
    },
    addValues: function(values) {
      var index, value;
      for (index in values) {
        value = values[index];
        if (!(index in this.aliases)) {
          this.values[index] = value;
        }
      }
      return true;
    },
    indexOf: function(key) {
      var i, k, _ref;
      _ref = this.keys;
      for (i in _ref) {
        k = _ref[i];
        if (key === k) {
          return i;
        }
      }
      return false;
    },
    save: function(index) {
      var value;
      this.values[index] = $("[index=" + index + "] input").val();
      value = this.values[index].length === 0 ? _last(this.keys[index].split('.')) : this.values[index];
      $.post('/v15n/save', {
        locale: this.locale,
        key: this.keys[index],
        value: this.values[index]
      }, __bind(function() {
        return this.processing.update(index, value);
      }, this));
      return this.updateCustom(this.keys[index], $("[index=" + index + "] input").val());
    },
    addCustom: function(key) {
      return $.post('/v15n/custom_sadd', {
        page: this.page,
        key: key
      }, __bind(function() {
        $('.ccontrol input', this.panel.body).val('');
        return this.panel.loadCustom();
      }, this));
    },
    deleteCustom: function(key, row) {
      return $.post('/v15n/custom_srem', {
        page: this.page,
        key: key
      }, function() {
        return row.remove();
      });
    },
    saveCustom: function(key, row) {
      var value;
      value = $('input', row).val();
      $.post('/v15n/save', {
        locale: this.locale,
        key: key,
        value: value
      });
      return this.updateTranslation(key, value);
    },
    updateCustom: function(key, value) {
      return $('.ctranslations>div>div', this.panel.body).each(function() {
        if ($(this).html() === key) {
          return $(this).nextAll('input').val(value);
        }
      });
    },
    updateTranslation: function(key, value) {
      var index;
      if (!(index = this.indexOf(key))) {
        return;
      }
      this.values[index] = value;
      $("[index=" + index + "] input").val(value);
      return this.processing.update(index, this.values[index].length === 0 ? _last(this.keys[index].split('.')) : this.values[index]);
    },
    process: function() {
      return this.processing.all();
    },
    setBounds: function(start, end) {
      return this.processing.setBounds(start, end);
    },
    processing: {
      all: function() {
        if (this.tester == null) {
          this.setDefaultBounds();
        }
        $('*:not(style,script,#v15n_panel,#v15n_panel *)').each(__bind(function(i, e) {
          $(e).removeAttr('v15n_key');
          this.forPropertiesOf(e, this.element);
          return true;
        }, this));
        return true;
      },
      forPropertiesOf: function(elem, iterator) {
        var attr, node, prop, properties, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _results, _results2;
        properties = (function() {
          _ref = elem.childNodes;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            node = _ref[_i];
            if (node.nodeType === Node.TEXT_NODE && this.test(node.data)) {
              _results.push(this.property(node));
            }
          }
          return _results;
        }.call(this));
        properties.concat((function() {
          _ref2 = elem.attributes;
          _results2 = [];
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            attr = _ref2[_j];
            if (this.test(attr.nodeValue)) {
              _results2.push(this.property(attr));
            }
          }
          return _results2;
        }.call(this)));
        for (_k = 0, _len3 = properties.length; _k < _len3; _k++) {
          prop = properties[_k];
          iterator.call(this, elem, prop);
        }
        return elem;
      },
      property: function(obj) {
        var prop, text;
        prop = {};
        text = obj instanceof Text;
        prop.__defineGetter__('value', function() {
          if (text) {
            return obj.data;
          } else {
            return obj.nodeValue;
          }
        });
        prop.__defineSetter__('value', function(value) {
          if (text) {
            return obj.data = value;
          } else {
            return obj.nodeValue = value;
          }
        });
        return prop;
      },
      element: function(element, prop) {
        return prop.value.replace(this.extractor, function(match) {
          var index, key;
          index = match.charCodeAt(0);
          key = _compact([$(element).attr('v15n_key')]).concat(index).join('|');
          $(element).attr('v15n_key', key);
          return match;
        });
      },
      update: function(index, value) {
        var alias, bchar, indices, indx, _fn, _i, _len, _ref, _results;
        indices = [index];
        _ref = v15n.aliases;
        for (alias in _ref) {
          indx = _ref[alias];
          if (indx === index) {
            indices.push(alias);
          }
        }
        _fn = function(indx) {
          bchar = String.fromCharCode(indx);
          return _results.push($("[v15n_key*=" + indx + "]").each(function() {
            return v15n.processing.forPropertiesOf(this, function(e, prop) {
              return prop.value = prop.value.replace(new RegExp("" + bchar + ".*?" + bchar, 'g'), "" + bchar + value + bchar);
            });
          }));
        };
        _results = [];
        for (_i = 0, _len = indices.length; _i < _len; _i++) {
          indx = indices[_i];
          _fn(indx);
        }
        return _results;
      },
      setBounds: function(start, end) {
        this.tester = new RegExp("[" + (String.fromCharCode(start)) + "-" + (String.fromCharCode(end)) + "]");
        return this.extractor = new RegExp("([" + (String.fromCharCode(start)) + "-" + (String.fromCharCode(end)) + "]).+?\\1", 'g');
      },
      setDefaultBounds: function() {
        return this.setBounds(40960, 42124);
      },
      test: function(str) {
        if (!str) {
          return false;
        }
        return this.tester.test(str);
      }
    },
    panel: {
      renderingMethod: 'list',
      render: function() {
        this.body = $('<div id="v15n_panel"/>').appendTo('body');
        this.body.append(v15n.panel.html);
        $('.locale', this.body).html(v15n.locale);
        $('.v15n_menu input', this.body).click(function() {
          v15n.panel.renderingMethod = $(this).val();
          return v15n.panel.renderTranslations();
        });
        $('.ccontrol a:first', this.body).click(__bind(function() {
          this.loadCustom();
          return false;
        }, this));
        $('.ccontrol a:last', this.body).click(function() {
          $(this).next().toggle();
          return false;
        });
        $('.ccontrol img', this.body).click(__bind(function() {
          return v15n.addCustom($('.ccontrol input', this.body).val());
        }, this));
        this.renderTranslations();
        this.loadCustom();
        this.body.draggable({
          handle: $.fn.draggable ? '.v15n_menu>h5' : void 0
        });
        return this.body;
      },
      renderTranslations: function() {
        $('.translations', this.body).children().remove();
        return this.rendering[this.renderingMethod].call(v15n);
      },
      loadCustom: function() {
        $('.ctranslations', this.body).html('Loading...');
        return $.get("/v15n/custom?page=" + v15n.page, __bind(function(custom) {
          v15n.custom = custom;
          $('.ctranslations', this.body).html('');
          return this.rendering.custom.call(v15n);
        }, this), 'json');
      },
      rendering: {
        list: function() {
          var index, key, _ref;
          _ref = this.keys;
          for (index in _ref) {
            key = _ref[index];
            this.panel.rendering.item.call(this, key, index, $('.translations', this.panel.body));
          }
          return this.panel;
        },
        tree: function() {
          var index, key, obj, parts, renderBlock, sortObj, tree, _fn, _ref;
          renderBlock = __bind(function(obj, el) {
            var block, key, value, _fn;
            _fn = function(key, value) {
              if (_isString(value)) {
                return this.panel.rendering.item.call(this, key, value, $('div:first', el), false);
              } else {
                block = $("<div><a href='#' style='font-weight: bold'>" + key + "</a><div class='block' style='display: none; margin-left: 8px;'></div></div>").appendTo($('div:first', el));
                $('a', block).click(function() {
                  $(this).next().toggle();
                  return false;
                });
                return renderBlock(value, block);
              }
            };
            for (key in obj) {
              value = obj[key];
              _fn.call(this, key, value);
            }
            return true;
          }, this);
          sortObj = function(obj) {
            var key, keys, sorted, _i, _len;
            sorted = {};
            keys = _select(_keys(obj), function(k) {
              return !_isString(obj[k]);
            }).sort().concat(_select(_keys(obj), function(k) {
              return _isString(obj[k]);
            }).sort());
            for (_i = 0, _len = keys.length; _i < _len; _i++) {
              key = keys[_i];
              sorted[key] = _isString(obj[key]) ? obj[key] : sortObj(obj[key]);
            }
            return sorted;
          };
          tree = {};
          _ref = this.keys;
          _fn = function(index, key) {
            parts = key.split('.');
            obj = _inject(parts.slice(0, parts.length - 2 + 1), tree, function(obj, k) {
              if (obj[k]) {
                return obj[k];
              } else {
                return obj[k] = {};
              }
            });
            return obj[key] = index;
          };
          for (index in _ref) {
            key = _ref[index];
            _fn(index, key);
          }
          renderBlock(sortObj(tree), $('.translations', this.body).append('<div class="block"/>'));
          return this.panel;
        },
        custom: function() {
          var key, row, value, _fn, _ref;
          _ref = this.custom;
          _fn = function(key, value) {
            row = $("<div><div style='float: left; width: 185px;'>" + key + "</div></div>").appendTo($('.ctranslations', this.panel.body));
            $('<div style="float: right;"><img src="/images/v15n_save.png" style="cursor: pointer"/></div>').appendTo(row).click(__bind(function() {
              return this.saveCustom(key, row);
            }, this));
            $('<div style="float: right;"><img src="/images/v15n_delete.png" style="cursor: pointer"/></div>').appendTo(row).click(__bind(function() {
              return this.deleteCustom(key, row);
            }, this));
            $("<input type='text' value='" + value + "' style='float: right'/>").appendTo(row);
            return $('<div class="clear"/>').appendTo(row);
          };
          for (key in _ref) {
            value = _ref[key];
            _fn.call(this, key, value);
          }
          return true;
        },
        item: (function() {
          var cycle, odd;
          odd = true;
          cycle = function() {
            odd = !odd;
            if (odd) {
              return 'odd';
            } else {
              return 'even';
            }
          };
          return function(key, index, canvas, full) {
            var keyName, row;
            if (full == null) {
              full = true;
            }
            keyName = full ? key : _last(key.split('.'));
            row = $("<div index='" + index + "' class='item " + (cycle()) + "'><div class='key'>" + keyName + "</div></div>").appendTo(canvas);
            $('<div style="float: right;"><img src="/images/v15n_save.png" style="cursor: pointer"/></div>').appendTo(row).click(__bind(function() {
              return this.save(index);
            }, this));
            $("<input type='text' value='" + this.values[index] + "' style='float: right'/>").appendTo(row);
            $('<div class="clear"/>').appendTo(row);
            return row;
          };
        })()
      }
    }
  };
  $.ajaxPrefilter('json', function(options, originalOptions) {
    if (originalOptions.success != null) {
      return options.success = function(obj) {
        if (obj.v15n != null) {
          v15n.addKeys(obj.v15n.keys);
          v15n.addValues(obj.v15n.values);
          delete obj.v15n;
        }
        originalOptions.success.apply(this, arguments);
        v15n.process();
        return v15n.panel.renderTranslations();
      };
    }
  });
  focusTimeout = false;
  $("[v15n_key]").live({
    mouseover: function(e) {
      var index;
      index = $(this).attr('v15n_key');
      if (/\|/.test(index)) {
        index = index.split('|')[0];
      }
      if (index in v15n.aliases) {
        index = v15n.aliases[index];
      }
      focusTimeout = setTimeout(function() {
        $('.translations .block', v15n.panel.body).hide();
        $("[index=" + index + "]", v15n.panel.body).parents(':hidden').show();
        return $("[index=" + index + "] input", v15n.panel.body).focus();
      }, 300);
      return e.stopPropagation();
    },
    mouseout: function() {
      if (focusTimeout) {
        clearTimeout(focusTimeout);
        return focusTimeout = false;
      }
    }
  });
  this.v15n.panel.html = '<div class="v15n_menu">\n  <h5>Current Locale: <span class="locale">?</span></h5>\n  <div class="control">\n    <span>View as:</span>\n    <input type="radio" name="v15n_rendering_method" id="v15n_rendering_method_list" value="list" checked="checked"/>\n    <label for="v15n_rendering_method_list">List</label>\n    <input type="radio" name="v15n_rendering_method" id="v15n_rendering_method_tree" value="tree"/>\n    <label for="v15n_rendering_method_tree">Tree</label>\n  </div>\n</div>\n<div class="translations"/>\n<div class="custom-translations">\n  <div class="ctranslations"/>\n  <div class="ccontrol">\n    <a href="#">Reload</a> |\n    <a href="#">Add...</a>\n    <div style="float: right; display: none;">\n      <img src="/images/v15n_save.png"style="cursor: pointer; float: right"/>\n      <input type="text" name="v15n_custom_key" id="v15n_custom_key" style="width:250px; float: right"/>\n    </div>\n    <div class="clear" />\n  </div>\n</div>';
}).call(this);
