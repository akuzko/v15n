(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.v18n = {
    process: function() {
      if (this.tester == null) {
        this.setDefaultBounds();
      }
      $('*:not(.v18n_processed):not(#v18n_panel)').each(function() {
        var attribute, node, _i, _j, _len, _len2, _ref, _ref2;
        $(this).addClass('v18n_processed');
        _ref = this.childNodes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          if (node.nodeType === Node.TEXT_NODE && v18n.test(node.data)) {
            v18n.processElement(this, node.data);
          }
        }
        _ref2 = this.attributes;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          attribute = _ref2[_j];
          if (v18n.test(attribute.nodeValue)) {
            v18n.processElement(this, attribute.nodeValue);
          }
        }
        return true;
      });
      return true;
    },
    processElement: function(element, text) {
      return text.replace(this.extractor, function(match) {
        var key, keyCode;
        keyCode = match.charCodeAt(0);
        key = [$(element).attr('v18n_key')].compact().concat(keyCode).join('|');
        $(element).attr('v18n_key', key);
        return match;
      });
    },
    setKeys: function(keys) {
      this.keys = keys;
    },
    setValues: function(values) {
      this.values = values;
    },
    addKeys: function(keys) {
      return $.extend(this.keys, keys);
    },
    addValues: function(values) {
      return $.extend(this.values, values);
    },
    panel: {
      renderingMethod: 'list',
      render: function() {
        this.body = $('<div id="v18n_panel"/>').appendTo('body');
        this.body.append('<div class="menu">\n  <h5>Current Locale: <span class="locale">?</span></h5>\n  <div class="control">\n    <span>View as:</span>\n    <input type="radio" name="v18n_rendering_method" id="v18n_rendering_method_list" value="list" checked="checked"/>\n    <label for="v18n_rendering_method_list">List</label>\n    <input type="radio" name="v18n_rendering_method" id="v18n_rendering_method_tree" value="tree"/>\n    <label for="v18n_rendering_method_tree">Tree</label>\n  </div>\n</div>\n<div class="translations"/>\n<div class="custom-translations">\n  <div class="ctranslations"/>\n  <div class="ccontrol">\n    <a href="#">Reload</a> |\n    <a href="#">Add...</a>\n    <div style="float: right; display: none;">\n      <img src="/images/v18n_save.png" style="cursor: pointer; float: right"/>\n      <input type="text" name="v18n_custom_key" id="v18n_custom_key" style="width:250px; float: right"/>\n    </div>\n    <div class="clear" />\n  </div>\n</div>');
        $('.locale', this.body).html(v18n.locale);
        $('.menu input', this.body).click(function() {
          v18n.panel.renderingMethod = $(this).val();
          return v18n.panel.renderTranslations();
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
          return $.post('/v18n/custom_sadd', {
            page: v18n.page,
            key: $('.ccontrol input', this.body).val()
          }, __bind(function() {
            $('.ccontrol input', this.body).val('');
            return this.loadCustom();
          }, this));
        }, this));
        this.renderTranslations();
        this.loadCustom();
        return this.body.draggable({
          handle: '.menu>h5'
        });
      },
      renderTranslations: function() {
        $('.translations', this.body).children().remove();
        return this.rendering[this.renderingMethod].call(v18n);
      },
      renderItem: (function() {
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
          var focusTimeout, keyName, row;
          if (full == null) {
            full = true;
          }
          keyName = full ? key : key.split('.').last();
          row = $("<div index='" + index + "' class='item " + (cycle()) + "'><div class='key'>" + keyName + "</div></div>").appendTo(canvas);
          $('<div style="float: right;"><img src="/images/v18n_save.png" style="cursor: pointer"/></div>').appendTo(row).click(__bind(function() {
            return this.save(index);
          }, this));
          $("<input type='text' value='" + this.values[index] + "' style='float: right'/>").appendTo(row);
          $('<div class="clear"/>').appendTo(row);
          focusTimeout = false;
          $("[v18n_key*=" + index + "]").bind({
            mouseover: __bind(function(e) {
              focusTimeout = setTimeout(__bind(function() {
                $('.translations .block', this.panel.body).hide();
                $("[index=" + index + "]").parents(':hidden').show();
                return $("[index=" + index + "] input").focus();
              }, this), 200);
              return e.stopPropagation();
            }, this),
            mouseout: function() {
              if (focusTimeout) {
                clearTimeout(focusTimeout);
                return focusTimeout = false;
              }
            }
          });
          return row;
        };
      })(),
      loadCustom: function() {
        $('.ctranslations', this.body).html('Loading...');
        return $.get("/v18n/custom?page=" + v18n.page, __bind(function(custom) {
          v18n.custom = custom;
          $('.ctranslations', this.body).html('');
          return this.rendering.custom.call(v18n);
        }, this), 'json');
      },
      rendering: {
        list: function() {
          var index, key, _ref;
          _ref = this.keys;
          for (index in _ref) {
            key = _ref[index];
            this.panel.renderItem.call(this, key, index, $('.translations', this.panel.body));
          }
          return this.panel;
        },
        tree: function() {
          var index, key, obj, parts, renderBlock, sortObj, tree, _fn, _ref;
          renderBlock = __bind(function(obj, el) {
            var block, key, value, _fn;
            _fn = function(key, value) {
              if (_.isString(value)) {
                return this.panel.renderItem.call(this, key, value, $('div:first', el), false);
              } else {
                block = $("<div><a href='#' style='font-weight: bold'>" + key + "</a><div class='block' style='display: none; margin-left: 15px;'></div></div>").appendTo($('div:first', el));
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
            keys = _.keys(obj).select(function(k) {
              return !_.isString(obj[k]);
            }).sort().concat(_.keys(obj).select(function(k) {
              return _.isString(obj[k]);
            }).sort());
            for (_i = 0, _len = keys.length; _i < _len; _i++) {
              key = keys[_i];
              sorted[key] = _.isString(obj[key]) ? obj[key] : sortObj(obj[key]);
            }
            return sorted;
          };
          tree = {};
          _ref = this.keys;
          _fn = function(index, key) {
            parts = key.split('.');
            obj = parts.slice(0, (parts.length - 2) + 1).inject(tree, function(obj, k) {
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
            row = $("<div><div style='float: left; width: 200px;'>" + key + "</div></div>").appendTo($('.ctranslations', this.panel.body));
            $('<div style="float: right;"><img src="/images/v18n_save.png" style="cursor: pointer"/></div>').appendTo(row).click(__bind(function() {
              return this.saveCustom(key, row);
            }, this));
            $("<input type='text' value='" + value + "' style='float: right'/>").appendTo(row);
            return $('<div class="clear"/>').appendTo(row);
          };
          for (key in _ref) {
            value = _ref[key];
            _fn.call(this, key, value);
          }
          return true;
        }
      }
    },
    save: function(index) {
      var bchar, value;
      this.values[index] = $("[index=" + index + "] input").val();
      value = this.values[index].length === 0 ? this.keys[index].split('.').last() : this.values[index];
      bchar = String.fromCharCode(index);
      return $.post('/v18n/save', {
        locale: this.locale,
        key: this.keys[index],
        value: this.values[index]
      }, function() {
        bchar = String.fromCharCode(index);
        return $("[v18n_key*=" + index + "]").each(function() {
          return $(this).html($(this).html().replace(new RegExp("" + bchar + ".*?" + bchar, 'g'), "" + bchar + value + bchar));
        });
      });
    },
    saveCustom: function(key, row) {
      var value;
      value = $('input', row).val();
      return $.post('/v18n/save', {
        locale: this.locale,
        key: key,
        value: value
      });
    },
    test: function(str) {
      if (!str) {
        return false;
      }
      return this.tester.test(str);
    },
    extract: function(text) {
      return text.match;
    },
    setBounds: function(start, end) {
      this.tester = new RegExp("[" + (String.fromCharCode(start)) + "-" + (String.fromCharCode(end)) + "]");
      return this.extractor = new RegExp("([" + (String.fromCharCode(start)) + "-" + (String.fromCharCode(end)) + "]).+?\\1", 'g');
    },
    setDefaultBounds: function() {
      return this.setBounds(40960, 42124);
    }
  };
}).call(this);
