$(document).ready(function () {
    $.areaSelect = function (init) {
        var Province, State, City;
        var CityJson;
        createDom();
        writeData();
        replyOperation();
        var myscrol0 = new iScroll("wrapper0", {
            hScroll: false, vScrollbar: false, onScrollEnd: function () {
            }
        });

        function createDom() {
            var html = '';
            html += '<div class="sg-mask">';
            html += '<div class="popups-box">';
            html += '<div class="title-min"><span class="query">Cancel</span>Please select region<span class="submit">OK</span></div>';
            html += '<div class="title-max"> Please select region <span class="close">X</span></div>';
            html += '<div class="result-box">';
            html += '<label>Selected</label>';
            html += '<input id="hasCheck" type="text" name="area">';
            html += '</div>';
            html += '<div class="tab-box">';
            html += '<div class="tab-menu">';
            html += '<ul>';
            html += '<li class="tab-1 isCheck">province</li>';
            html += '<li class="tab-2">City</li>';
            html += '<li class="tab-3">Districts</li>';
            html += '</ul>';
            html += '</div>';
            html += '<div class="content-box">';
            html += '<div id="wrapper0" class="tab-content tab-list-1 isBlock">';
            html += '<ul></ul>';
            html += '</div>';
            html += '<div id="wrapper1"  class="tab-content tab-list-2">';
            html += '<ul></ul>';
            html += '</div>';
            html += '<div id="wrapper2"  class="tab-content tab-list-3">';
            html += '<ul></ul>';
            html += '</div>';
            html += '</div>';
            html += '</div> ';
            html += '<div class="footer">';
            html += '<button id="submitBtn">Ok</button>';
            html += '</div> ';
            html += '</div>';
            html += '</div>';
            $('body').append(html);
            $(".popups-box").show().animate({bottom: '0px'})
        }

        function setDomStyle() {
        }

        function replyOperation() {
            var provinceDom = '';
            var regionCode = 11;
            var cityCode = 01;
            var listOne = $('.tab-list-1');
            var listtwo = $('.tab-list-2');
            var listthree = $('.tab-list-3');
            $('.tab-1').click(function () {
                listOne.addClass('isBlock').siblings().removeClass('isBlock');
                $(this).addClass('isCheck').siblings().removeClass('isCheck');
            })
            $('.tab-2').click(function () {
                listtwo.addClass('isBlock').siblings().removeClass('isBlock');
                $(this).addClass('isCheck').siblings().removeClass('isCheck');
            })
            $('.tab-3').click(function () {
                listthree.addClass('isBlock').siblings().removeClass('isBlock');
                $(this).addClass('isCheck').siblings().removeClass('isCheck');
            })
            for (var i = 0; i < CityJson.length; i++) {
                provinceDom += '<li><a>' + CityJson[i].region.name + '<input value=' + CityJson[i].region.code + ' style="display:none"></a></li>';
            }
            $('.tab-list-1 ul').html(provinceDom);
            $('.tab-list-1 li a').click(function () {
                $(this).parent().addClass('minISClick').siblings().removeClass('minISClick');
                regionCode = $(this).children('input').val();
                Province = $(this).text();
                $('#hasCheck').val(Province);
                $('.tab-list-2 ul').empty();
                $('.tab-list-3 ul').empty();
                createState();
                $('.tab-list-2 li a').click(function () {
                    $(this).parent().addClass('minISClick').siblings().removeClass('minISClick');
                    cityCode = $(this).children('input').val();
                    State = $(this).text();
                    $('#hasCheck').val(Province + '-' + State);
                    $('.tab-list-3 ul').empty();
                    createCity();
                    $('.tab-list-3 li a').click(function () {
                        $(this).parent().addClass('minISClick').siblings().removeClass('minISClick');
                        City = $(this).text();
                        $('#hasCheck').val(Province + '-' + State + '-' + City);
                    })
                })
            })

            function createState() {
                var stateDom = '';
                for (var j = 0; j < CityJson.length; j++) {
                    if (CityJson[j].region.code == regionCode) {
                        for (var k = 0; k < CityJson[j].region.state.length; k++) {
                            stateDom += '<li><a>' + CityJson[j].region.state[k].name + '<input value="' + CityJson[j].region.state[k].code + '" style="display:none"></a></li>';
                        }
                        $('.tab-list-2 ul').html(stateDom);
                    }
                }
                $('.tab-2').click();
                var myscrol1 = new iScroll("wrapper1", {hScroll: false, vScrollbar: false,});
            }

            function createCity() {
                var cityDom = '';
                for (var j = 0; j < CityJson.length; j++) {
                    if (CityJson[j].region.code == regionCode) {
                        for (var k = 0; k < CityJson[j].region.state.length; k++) {
                            if (CityJson[j].region.state[k].code == cityCode) {
                                for (var l = 0; l < CityJson[j].region.state[k].city.length; l++) {
                                    cityDom += '<li><a>' + CityJson[j].region.state[k].city[l].name + '<input value="' + CityJson[j].region.state[k].city[l].code + '" style="display:none"></a></li>';
                                }
                                $('.tab-list-3 ul').html(cityDom);
                            }
                        }
                    }
                }
                $('.tab-3').click();
                var myscrol2 = new iScroll("wrapper2", {hScroll: false, vScrollbar: false,});
            }
        }

        $('.popups-box .close').click(function () {
            $(init.choose).val($('#hasCheck').val());
            $('.sg-mask').css('display', 'none');
            $('.sg-mask').remove();
        });
        $('#submitBtn').click(function () {
            $(init.choose).val($('#hasCheck').val());
            $('.sg-mask').css('display', 'none');
            $('.sg-mask').remove();
        });
        $('.title-min .query').on('click', function () {
            $(init.choose).val();
            $(".popups-box").show().animate({bottom: '-251px'}, function () {
                $('.sg-mask').css('display', 'none');
                $('.sg-mask').remove();
            })
        })
        $('.title-min .submit').on('click', function () {
            $(init.choose).val($('#hasCheck').val());
            $(".popups-box").show().animate({bottom: '-251px'}, function () {
                $('.sg-mask').css('display', 'none');
                $('.sg-mask').remove();
            })
        })

        function writeData() {
            CityJson = [
  {
    "region": {
      "name": "BEI JING",
      "code": 1,
      "state": [
        {
          "name": "SHI XIA QU",
          "code": 1,
          "city": [
            {
              "name": "DONG CHENG QU",
              "code": 1
            },
            {
              "name": "XI CHENG QU",
              "code": 2
            },
            {
              "name": "HAI DIAN QU",
              "code": 3
            },
            {
              "name": "CHAO YANG QU",
              "code": 4
            },
            {
              "name": "CHONG WEN QU",
              "code": 5
            },
            {
              "name": "XUAN WU QU",
              "code": 6
            },
            {
              "name": "FENG TAI QU",
              "code": 7
            },
            {
              "name": "SHI JING SHAN QU",
              "code": 8
            },
            {
              "name": "FANG SHAN QU",
              "code": 9
            },
            {
              "name": "MEN TOU GOU QU",
              "code": 10
            },
            {
              "name": "TONG ZHOU QU",
              "code": 11
            },
            {
              "name": "SHUN YI QU",
              "code": 12
            },
            {
              "name": "CHANG PING QU",
              "code": 13
            },
            {
              "name": "HUAI ROU QU",
              "code": 14
            },
            {
              "name": "PING GU QU",
              "code": 15
            },
            {
              "name": "DA XING QU",
              "code": 16
            },
            {
              "name": "MI YUN XIAN",
              "code": 17
            },
            {
              "name": "YAN QING XIAN",
              "code": 18
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "AN HUI",
      "code": 2,
      "state": [
        {
          "name": "AN QING",
          "code": 1,
          "city": [
            {
              "name": "YING JIANG QU",
              "code": 1
            },
            {
              "name": "DA GUAN QU",
              "code": 2
            },
            {
              "name": "YI XIU QU",
              "code": 3
            },
            {
              "name": "TONG CHENG SHI",
              "code": 4
            },
            {
              "name": "HUAI NING XIAN",
              "code": 5
            },
            {
              "name": "ZONG YANG XIAN",
              "code": 6
            },
            {
              "name": "QIAN SHAN XIAN",
              "code": 7
            },
            {
              "name": "TAI HU XIAN",
              "code": 8
            },
            {
              "name": "SU SONG XIAN",
              "code": 9
            },
            {
              "name": "WANG JIANG XIAN",
              "code": 10
            },
            {
              "name": "YUE XI XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "BENG BU",
          "code": 2,
          "city": [
            {
              "name": "ZHONG SHI QU",
              "code": 1
            },
            {
              "name": "DONG SHI QU",
              "code": 2
            },
            {
              "name": "XI SHI QU",
              "code": 3
            },
            {
              "name": "JIAO QU",
              "code": 4
            },
            {
              "name": "HUAI YUAN XIAN",
              "code": 5
            },
            {
              "name": "WU HE XIAN",
              "code": 6
            },
            {
              "name": "GU ZHEN XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "CHAO HU",
          "code": 3,
          "city": [
            {
              "name": "JU CHAO QU",
              "code": 1
            },
            {
              "name": "LU JIANG XIAN",
              "code": 2
            },
            {
              "name": "WU WEI XIAN",
              "code": 3
            },
            {
              "name": "HAN SHAN XIAN",
              "code": 4
            },
            {
              "name": "HE XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "CHI ZHOU",
          "code": 4,
          "city": [
            {
              "name": "GUI CHI QU",
              "code": 1
            },
            {
              "name": "DONG ZHI XIAN",
              "code": 2
            },
            {
              "name": "SHI TAI XIAN",
              "code": 3
            },
            {
              "name": "QING YANG XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "CHU ZHOU",
          "code": 5,
          "city": [
            {
              "name": "LANG YA QU",
              "code": 1
            },
            {
              "name": "NAN QIAO QU",
              "code": 2
            },
            {
              "name": "TIAN CHANG SHI",
              "code": 3
            },
            {
              "name": "MING GUANG SHI",
              "code": 4
            },
            {
              "name": "LAI AN XIAN",
              "code": 5
            },
            {
              "name": "QUAN JIAO XIAN",
              "code": 6
            },
            {
              "name": "DING YUAN XIAN",
              "code": 7
            },
            {
              "name": "FENG YANG XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "FU YANG",
          "code": 6,
          "city": [
            {
              "name": "BENG SHAN QU",
              "code": 1
            },
            {
              "name": "LONG ZI HU QU",
              "code": 2
            },
            {
              "name": "YU HUI QU",
              "code": 3
            },
            {
              "name": "HUAI SHANG QU",
              "code": 4
            },
            {
              "name": "YING ZHOU QU",
              "code": 5
            },
            {
              "name": "YING DONG QU",
              "code": 6
            },
            {
              "name": "YING QUAN QU",
              "code": 7
            },
            {
              "name": "JIE SHOU SHI",
              "code": 8
            },
            {
              "name": "LIN QUAN XIAN",
              "code": 9
            },
            {
              "name": "TAI HE XIAN",
              "code": 10
            },
            {
              "name": "FU NAN XIAN",
              "code": 11
            },
            {
              "name": "YING SHANG XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "HUAI BEI",
          "code": 7,
          "city": [
            {
              "name": "XIANG SHAN QU",
              "code": 1
            },
            {
              "name": "DU JI QU",
              "code": 2
            },
            {
              "name": "LIE SHAN QU",
              "code": 3
            },
            {
              "name": "SUI XI XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "HUAI NAN",
          "code": 8,
          "city": [
            {
              "name": "TIAN JIA AN QU",
              "code": 1
            },
            {
              "name": "DA TONG QU",
              "code": 2
            },
            {
              "name": "XIE JIA JI QU",
              "code": 3
            },
            {
              "name": "BA GONG SHAN QU",
              "code": 4
            },
            {
              "name": "PAN JI QU",
              "code": 5
            },
            {
              "name": "FENG TAI XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "HUANG SHAN",
          "code": 9,
          "city": [
            {
              "name": "TUN XI QU",
              "code": 1
            },
            {
              "name": "HUANG SHAN QU",
              "code": 2
            },
            {
              "name": "HUI ZHOU QU",
              "code": 3
            },
            {
              "name": "SHE XIAN",
              "code": 4
            },
            {
              "name": "XIU NING XIAN",
              "code": 5
            },
            {
              "name": "YI XIAN",
              "code": 6
            },
            {
              "name": "QI MEN XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "LU AN",
          "code": 10,
          "city": [
            {
              "name": "JIN AN QU",
              "code": 1
            },
            {
              "name": "YU AN QU",
              "code": 2
            },
            {
              "name": "SHOU XIAN",
              "code": 3
            },
            {
              "name": "HUO QIU XIAN",
              "code": 4
            },
            {
              "name": "SHU CHENG XIAN",
              "code": 5
            },
            {
              "name": "JIN ZHAI XIAN",
              "code": 6
            },
            {
              "name": "HUO SHAN XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "MA AN SHAN",
          "code": 11,
          "city": [
            {
              "name": "YU SHAN QU",
              "code": 1
            },
            {
              "name": "HUA SHAN QU",
              "code": 2
            },
            {
              "name": "JIN JIA ZHUANG QU",
              "code": 3
            },
            {
              "name": "DANG TU XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "SU ZHOU",
          "code": 12,
          "city": [
            {
              "name": "YONG QIAO QU",
              "code": 1
            },
            {
              "name": "DANG SHAN XIAN",
              "code": 2
            },
            {
              "name": "XIAO XIAN",
              "code": 3
            },
            {
              "name": "LING BI XIAN",
              "code": 4
            },
            {
              "name": "SI XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "TONG LING",
          "code": 13,
          "city": [
            {
              "name": "TONG GUAN SHAN QU",
              "code": 1
            },
            {
              "name": "SHI ZI SHAN QU",
              "code": 2
            },
            {
              "name": "JIAO QU",
              "code": 3
            },
            {
              "name": "TONG LING XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "WU HU",
          "code": 14,
          "city": [
            {
              "name": "JING HU QU",
              "code": 1
            },
            {
              "name": "YI JIANG QU",
              "code": 2
            },
            {
              "name": "JIU JIANG QU",
              "code": 3
            },
            {
              "name": "SAN SHAN QU",
              "code": 4
            },
            {
              "name": "WU HU XIAN",
              "code": 5
            },
            {
              "name": "FAN CHANG XIAN",
              "code": 6
            },
            {
              "name": "NAN LING XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "XUAN CHENG",
          "code": 15,
          "city": [
            {
              "name": "XUAN ZHOU QU",
              "code": 1
            },
            {
              "name": "NING GUO SHI",
              "code": 2
            },
            {
              "name": "LANG XI XIAN",
              "code": 3
            },
            {
              "name": "GUANG DE XIAN",
              "code": 4
            },
            {
              "name": "JING XIAN",
              "code": 5
            },
            {
              "name": "JI XI XIAN",
              "code": 6
            },
            {
              "name": "JING DE XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "BO ZHOU",
          "code": 16,
          "city": [
            {
              "name": "GUO YANG XIAN",
              "code": 1
            },
            {
              "name": "MENG CHENG XIAN",
              "code": 2
            },
            {
              "name": "LI XIN XIAN",
              "code": 3
            },
            {
              "name": "QIAO CHENG QU",
              "code": 4
            }
          ]
        },
        {
          "name": "HE FEI",
          "code": 17,
          "city": [
            {
              "name": "LU YANG QU",
              "code": 1
            },
            {
              "name": "YAO HAI QU",
              "code": 2
            },
            {
              "name": "SHU SHAN QU",
              "code": 3
            },
            {
              "name": "BAO HE QU",
              "code": 4
            },
            {
              "name": "CHANG FENG XIAN",
              "code": 5
            },
            {
              "name": "FEI DONG XIAN",
              "code": 6
            },
            {
              "name": "FEI XI XIAN",
              "code": 7
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "FU JIAN",
      "code": 3,
      "state": [
        {
          "name": "FU ZHOU",
          "code": 1,
          "city": [
            {
              "name": "GU LOU QU",
              "code": 1
            },
            {
              "name": "TAI JIANG QU",
              "code": 2
            },
            {
              "name": "CANG SHAN QU",
              "code": 3
            },
            {
              "name": "MA WEI QU",
              "code": 4
            },
            {
              "name": "JIN AN QU",
              "code": 5
            },
            {
              "name": "FU QING SHI",
              "code": 6
            },
            {
              "name": "CHANG LE SHI",
              "code": 7
            },
            {
              "name": "MIN HOU XIAN",
              "code": 8
            },
            {
              "name": "LIAN JIANG XIAN",
              "code": 9
            },
            {
              "name": "LUO YUAN XIAN",
              "code": 10
            },
            {
              "name": "MIN QING XIAN",
              "code": 11
            },
            {
              "name": "YONG TAI XIAN",
              "code": 12
            },
            {
              "name": "PING TAN XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "LONG YAN",
          "code": 2,
          "city": [
            {
              "name": "XIN LUO QU",
              "code": 1
            },
            {
              "name": "ZHANG PING SHI",
              "code": 2
            },
            {
              "name": "CHANG TING XIAN",
              "code": 3
            },
            {
              "name": "YONG DING XIAN",
              "code": 4
            },
            {
              "name": "SHANG HANG XIAN",
              "code": 5
            },
            {
              "name": "WU PING XIAN",
              "code": 6
            },
            {
              "name": "LIAN CHENG XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "NAN PING",
          "code": 3,
          "city": [
            {
              "name": "YAN PING QU",
              "code": 1
            },
            {
              "name": "SHAO WU SHI",
              "code": 2
            },
            {
              "name": "WU YI SHAN SHI",
              "code": 3
            },
            {
              "name": "JIAN OU SHI",
              "code": 4
            },
            {
              "name": "JIAN YANG SHI",
              "code": 5
            },
            {
              "name": "SHUN CHANG XIAN",
              "code": 6
            },
            {
              "name": "PU CHENG XIAN",
              "code": 7
            },
            {
              "name": "GUANG ZE XIAN",
              "code": 8
            },
            {
              "name": "SONG XI XIAN",
              "code": 9
            },
            {
              "name": "ZHENG HE XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "NING DE",
          "code": 4,
          "city": [
            {
              "name": "JIAO CHENG QU",
              "code": 1
            },
            {
              "name": "FU AN SHI",
              "code": 2
            },
            {
              "name": "FU DING SHI",
              "code": 3
            },
            {
              "name": "XIA PU XIAN",
              "code": 4
            },
            {
              "name": "GU TIAN XIAN",
              "code": 5
            },
            {
              "name": "PING NAN XIAN",
              "code": 6
            },
            {
              "name": "SHOU NING XIAN",
              "code": 7
            },
            {
              "name": "ZHOU NING XIAN",
              "code": 8
            },
            {
              "name": "ZHE RONG XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "PU TIAN",
          "code": 5,
          "city": [
            {
              "name": "CHENG XIANG QU",
              "code": 1
            },
            {
              "name": "HAN JIANG QU",
              "code": 2
            },
            {
              "name": "LI CHENG QU",
              "code": 3
            },
            {
              "name": "XIU YU QU",
              "code": 4
            },
            {
              "name": "XIAN YOU XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "QUAN ZHOU",
          "code": 6,
          "city": [
            {
              "name": "LI CHENG QU",
              "code": 1
            },
            {
              "name": "FENG ZE QU",
              "code": 2
            },
            {
              "name": "LUO JIANG QU",
              "code": 3
            },
            {
              "name": "QING MENG KAI FA QU",
              "code": 4
            },
            {
              "name": "QUAN GANG QU",
              "code": 5
            },
            {
              "name": "SHI SHI SHI",
              "code": 6
            },
            {
              "name": "JIN JIANG SHI",
              "code": 7
            },
            {
              "name": "NAN AN SHI",
              "code": 8
            },
            {
              "name": "HUI AN XIAN",
              "code": 9
            },
            {
              "name": "AN XI XIAN",
              "code": 10
            },
            {
              "name": "YONG CHUN XIAN",
              "code": 11
            },
            {
              "name": "DE HUA XIAN",
              "code": 12
            },
            {
              "name": "JIN MEN XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "SAN MING",
          "code": 7,
          "city": [
            {
              "name": "MEI LIE QU",
              "code": 1
            },
            {
              "name": "SAN YUAN QU",
              "code": 2
            },
            {
              "name": "YONG AN SHI",
              "code": 3
            },
            {
              "name": "MING XI XIAN",
              "code": 4
            },
            {
              "name": "QING LIU XIAN",
              "code": 5
            },
            {
              "name": "NING HUA XIAN",
              "code": 6
            },
            {
              "name": "DA TIAN XIAN",
              "code": 7
            },
            {
              "name": "YOU XI XIAN",
              "code": 8
            },
            {
              "name": "SHA XIAN",
              "code": 9
            },
            {
              "name": "JIANG LE XIAN",
              "code": 10
            },
            {
              "name": "TAI NING XIAN",
              "code": 11
            },
            {
              "name": "JIAN NING XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "XIA MEN",
          "code": 8,
          "city": [
            {
              "name": "SI MING QU",
              "code": 1
            },
            {
              "name": "HAI CANG QU",
              "code": 2
            },
            {
              "name": "HU LI QU",
              "code": 3
            },
            {
              "name": "JI MEI QU",
              "code": 4
            },
            {
              "name": "TONG AN QU",
              "code": 5
            },
            {
              "name": "XIANG AN QU",
              "code": 6
            }
          ]
        },
        {
          "name": "ZHANG ZHOU",
          "code": 9,
          "city": [
            {
              "name": "XIANG CHENG QU",
              "code": 1
            },
            {
              "name": "LONG WEN QU",
              "code": 2
            },
            {
              "name": "LONG HAI SHI",
              "code": 3
            },
            {
              "name": "YUN XIAO XIAN",
              "code": 4
            },
            {
              "name": "ZHANG PU XIAN",
              "code": 5
            },
            {
              "name": "ZHAO AN XIAN",
              "code": 6
            },
            {
              "name": "CHANG TAI XIAN",
              "code": 7
            },
            {
              "name": "DONG SHAN XIAN",
              "code": 8
            },
            {
              "name": "NAN JING XIAN",
              "code": 9
            },
            {
              "name": "PING HE XIAN",
              "code": 10
            },
            {
              "name": "HUA AN XIAN",
              "code": 11
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "GAN SU",
      "code": 4,
      "state": [
        {
          "name": "LAN ZHOU",
          "code": 1,
          "city": [
            {
              "name": "GAO LAN XIAN",
              "code": 1
            },
            {
              "name": "CHENG GUAN QU",
              "code": 2
            },
            {
              "name": "QI LI HE QU",
              "code": 3
            },
            {
              "name": "XI GU QU",
              "code": 4
            },
            {
              "name": "AN NING QU",
              "code": 5
            },
            {
              "name": "HONG GU QU",
              "code": 6
            },
            {
              "name": "YONG DENG XIAN",
              "code": 7
            },
            {
              "name": "YU ZHONG XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "BAI YIN",
          "code": 2,
          "city": [
            {
              "name": "BAI YIN QU",
              "code": 1
            },
            {
              "name": "PING CHUAN QU",
              "code": 2
            },
            {
              "name": "HUI NING XIAN",
              "code": 3
            },
            {
              "name": "JING TAI XIAN",
              "code": 4
            },
            {
              "name": "JING YUAN XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "DING XI",
          "code": 3,
          "city": [
            {
              "name": "LIN TAO XIAN",
              "code": 1
            },
            {
              "name": "LONG XI XIAN",
              "code": 2
            },
            {
              "name": "TONG WEI XIAN",
              "code": 3
            },
            {
              "name": "WEI YUAN XIAN",
              "code": 4
            },
            {
              "name": "ZHANG XIAN",
              "code": 5
            },
            {
              "name": "MIN XIAN",
              "code": 6
            },
            {
              "name": "AN DING QU",
              "code": 7
            },
            {
              "name": "AN DING QU",
              "code": 8
            }
          ]
        },
        {
          "name": "GAN NAN",
          "code": 4,
          "city": [
            {
              "name": "HE ZUO SHI",
              "code": 1
            },
            {
              "name": "LIN TAN XIAN",
              "code": 2
            },
            {
              "name": "ZHUO NI XIAN",
              "code": 3
            },
            {
              "name": "ZHOU QU XIAN",
              "code": 4
            },
            {
              "name": "DIE BU XIAN",
              "code": 5
            },
            {
              "name": "MA QU XIAN",
              "code": 6
            },
            {
              "name": "LU QU XIAN",
              "code": 7
            },
            {
              "name": "XIA HE XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "JIA YU GUAN",
          "code": 5,
          "city": [
            {
              "name": "JIA YU GUAN SHI",
              "code": 1
            }
          ]
        },
        {
          "name": "JIN CHANG",
          "code": 6,
          "city": [
            {
              "name": "JIN CHUAN QU",
              "code": 1
            },
            {
              "name": "YONG CHANG XIAN",
              "code": 2
            }
          ]
        },
        {
          "name": "JIU QUAN",
          "code": 7,
          "city": [
            {
              "name": "SU ZHOU QU",
              "code": 1
            },
            {
              "name": "YU MEN SHI",
              "code": 2
            },
            {
              "name": "DUN HUANG SHI",
              "code": 3
            },
            {
              "name": "JIN TA XIAN",
              "code": 4
            },
            {
              "name": "GUA ZHOU XIAN",
              "code": 5
            },
            {
              "name": "SU BEI",
              "code": 6
            },
            {
              "name": "A KE SAI",
              "code": 7
            }
          ]
        },
        {
          "name": "LIN XIA",
          "code": 8,
          "city": [
            {
              "name": "LIN XIA SHI",
              "code": 1
            },
            {
              "name": "LIN XIA XIAN",
              "code": 2
            },
            {
              "name": "KANG LE XIAN",
              "code": 3
            },
            {
              "name": "YONG JING XIAN",
              "code": 4
            },
            {
              "name": "GUANG HE XIAN",
              "code": 5
            },
            {
              "name": "HE ZHENG XIAN",
              "code": 6
            },
            {
              "name": "DONG XIANG ZU ZI ZHI XIAN",
              "code": 7
            },
            {
              "name": "JI SHI SHAN",
              "code": 8
            }
          ]
        },
        {
          "name": "LONG NAN",
          "code": 9,
          "city": [
            {
              "name": "CHENG XIAN",
              "code": 1
            },
            {
              "name": "HUI XIAN",
              "code": 2
            },
            {
              "name": "KANG XIAN",
              "code": 3
            },
            {
              "name": "LI XIAN",
              "code": 4
            },
            {
              "name": "LIANG DANG XIAN",
              "code": 5
            },
            {
              "name": "WEN XIAN",
              "code": 6
            },
            {
              "name": "XI HE XIAN",
              "code": 7
            },
            {
              "name": "DANG CHANG XIAN",
              "code": 8
            },
            {
              "name": "WU DU QU",
              "code": 9
            }
          ]
        },
        {
          "name": "PING LIANG",
          "code": 10,
          "city": [
            {
              "name": "CHONG XIN XIAN",
              "code": 1
            },
            {
              "name": "HUA TING XIAN",
              "code": 2
            },
            {
              "name": "JING NING XIAN",
              "code": 3
            },
            {
              "name": "LING TAI XIAN",
              "code": 4
            },
            {
              "name": "KONG TONG QU",
              "code": 5
            },
            {
              "name": "ZHUANG LANG XIAN",
              "code": 6
            },
            {
              "name": "JING CHUAN XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "QING YANG",
          "code": 11,
          "city": [
            {
              "name": "HE SHUI XIAN",
              "code": 1
            },
            {
              "name": "HUA CHI XIAN",
              "code": 2
            },
            {
              "name": "HUAN XIAN",
              "code": 3
            },
            {
              "name": "NING XIAN",
              "code": 4
            },
            {
              "name": "QING CHENG XIAN",
              "code": 5
            },
            {
              "name": "XI FENG QU",
              "code": 6
            },
            {
              "name": "ZHEN YUAN XIAN",
              "code": 7
            },
            {
              "name": "ZHENG NING XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "TIAN SHUI",
          "code": 12,
          "city": [
            {
              "name": "GAN GU XIAN",
              "code": 1
            },
            {
              "name": "QIN AN XIAN",
              "code": 2
            },
            {
              "name": "QING SHUI XIAN",
              "code": 3
            },
            {
              "name": "QIN ZHOU QU",
              "code": 4
            },
            {
              "name": "MAI JI QU",
              "code": 5
            },
            {
              "name": "WU SHAN XIAN",
              "code": 6
            },
            {
              "name": "ZHANG JIA CHUAN",
              "code": 7
            }
          ]
        },
        {
          "name": "WU WEI",
          "code": 13,
          "city": [
            {
              "name": "GU LANG XIAN",
              "code": 1
            },
            {
              "name": "MIN QIN XIAN",
              "code": 2
            },
            {
              "name": "TIAN ZHU",
              "code": 3
            },
            {
              "name": "LIANG ZHOU QU",
              "code": 4
            }
          ]
        },
        {
          "name": "ZHANG YE",
          "code": 14,
          "city": [
            {
              "name": "GAO TAI XIAN",
              "code": 1
            },
            {
              "name": "LIN ZE XIAN",
              "code": 2
            },
            {
              "name": "MIN YUE XIAN",
              "code": 3
            },
            {
              "name": "SHAN DAN XIAN",
              "code": 4
            },
            {
              "name": "SU NAN",
              "code": 5
            },
            {
              "name": "GAN ZHOU QU",
              "code": 6
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "GUANG DONG",
      "code": 5,
      "state": [
        {
          "name": "GUANG ZHOU",
          "code": 1,
          "city": [
            {
              "name": "CONG HUA SHI",
              "code": 1
            },
            {
              "name": "TIAN HE QU",
              "code": 2
            },
            {
              "name": "DONG SHAN QU",
              "code": 3
            },
            {
              "name": "BAI YUN QU",
              "code": 4
            },
            {
              "name": "HAI ZHU QU",
              "code": 5
            },
            {
              "name": "LI WAN QU",
              "code": 6
            },
            {
              "name": "YUE XIU QU",
              "code": 7
            },
            {
              "name": "HUANG PU QU",
              "code": 8
            },
            {
              "name": "PAN YU QU",
              "code": 9
            },
            {
              "name": "HUA DU QU",
              "code": 10
            },
            {
              "name": "ZENG CHENG QU",
              "code": 11
            },
            {
              "name": "CONG HUA QU",
              "code": 12
            },
            {
              "name": "SHI JIAO",
              "code": 13
            }
          ]
        },
        {
          "name": "SHEN ZHEN",
          "code": 2,
          "city": [
            {
              "name": "FU TIAN QU",
              "code": 1
            },
            {
              "name": "LUO HU QU",
              "code": 2
            },
            {
              "name": "NAN SHAN QU",
              "code": 3
            },
            {
              "name": "BAO AN QU",
              "code": 4
            },
            {
              "name": "LONG GANG QU",
              "code": 5
            },
            {
              "name": "YAN TIAN QU",
              "code": 6
            }
          ]
        },
        {
          "name": "CHAO ZHOU",
          "code": 3,
          "city": [
            {
              "name": "XIANG QIAO QU",
              "code": 1
            },
            {
              "name": "CHAO AN XIAN",
              "code": 2
            },
            {
              "name": "RAO PING XIAN",
              "code": 3
            }
          ]
        },
        {
          "name": "DONG GUAN",
          "code": 4,
          "city": [
            {
              "name": "NAN CHENG QU",
              "code": 1
            },
            {
              "name": "DONG CHENG QU",
              "code": 2
            },
            {
              "name": "WAN JIANG QU",
              "code": 3
            },
            {
              "name": "GUAN CHENG QU",
              "code": 4
            },
            {
              "name": "SHI LONG ZHEN",
              "code": 5
            },
            {
              "name": "HU MEN ZHEN",
              "code": 6
            },
            {
              "name": "MA YONG ZHEN",
              "code": 7
            },
            {
              "name": "DAO JIAO ZHEN",
              "code": 8
            },
            {
              "name": "SHI JIE ZHEN",
              "code": 9
            },
            {
              "name": "SHA TIAN ZHEN",
              "code": 10
            },
            {
              "name": "WANG NIU DUN ZHEN",
              "code": 11
            },
            {
              "name": "HONG MEI ZHEN",
              "code": 12
            },
            {
              "name": "CHA SHAN ZHEN",
              "code": 13
            },
            {
              "name": "LIAO BU ZHEN",
              "code": 14
            },
            {
              "name": "DA LING SHAN ZHEN",
              "code": 15
            },
            {
              "name": "DA LANG ZHEN",
              "code": 16
            },
            {
              "name": "HUANG JIANG ZHEN",
              "code": 17
            },
            {
              "name": "ZHANG MU TOU",
              "code": 18
            },
            {
              "name": "FENG GANG ZHEN",
              "code": 19
            },
            {
              "name": "TANG SHA ZHEN",
              "code": 20
            },
            {
              "name": "XIE GANG ZHEN",
              "code": 21
            },
            {
              "name": "HOU JIE ZHEN",
              "code": 22
            },
            {
              "name": "QING XI ZHEN",
              "code": 23
            },
            {
              "name": "CHANG PING ZHEN",
              "code": 24
            },
            {
              "name": "QIAO TOU ZHEN",
              "code": 25
            },
            {
              "name": "HENG LI ZHEN",
              "code": 26
            },
            {
              "name": "DONG KENG ZHEN",
              "code": 27
            },
            {
              "name": "QI SHI ZHEN",
              "code": 28
            },
            {
              "name": "SHI PAI ZHEN",
              "code": 29
            },
            {
              "name": "CHANG AN ZHEN",
              "code": 30
            },
            {
              "name": "ZHONG TANG ZHEN",
              "code": 31
            },
            {
              "name": "GAO BU ZHEN",
              "code": 32
            }
          ]
        },
        {
          "name": "FO SHAN",
          "code": 5,
          "city": [
            {
              "name": "CHAN CHENG QU",
              "code": 1
            },
            {
              "name": "NAN HAI QU",
              "code": 2
            },
            {
              "name": "SHUN DE QU",
              "code": 3
            },
            {
              "name": "SAN SHUI QU",
              "code": 4
            },
            {
              "name": "GAO MING QU",
              "code": 5
            }
          ]
        },
        {
          "name": "HE YUAN",
          "code": 6,
          "city": [
            {
              "name": "DONG YUAN XIAN",
              "code": 1
            },
            {
              "name": "HE PING XIAN",
              "code": 2
            },
            {
              "name": "YUAN CHENG QU",
              "code": 3
            },
            {
              "name": "LIAN PING XIAN",
              "code": 4
            },
            {
              "name": "LONG CHUAN XIAN",
              "code": 5
            },
            {
              "name": "ZI JIN XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "HUI ZHOU",
          "code": 7,
          "city": [
            {
              "name": "HUI YANG QU",
              "code": 1
            },
            {
              "name": "HUI CHENG QU",
              "code": 2
            },
            {
              "name": "DA YA WAN",
              "code": 3
            },
            {
              "name": "BO LUO XIAN",
              "code": 4
            },
            {
              "name": "HUI DONG XIAN",
              "code": 5
            },
            {
              "name": "LONG MEN XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "JIANG MEN",
          "code": 8,
          "city": [
            {
              "name": "JIANG HAI QU",
              "code": 1
            },
            {
              "name": "PENG JIANG QU",
              "code": 2
            },
            {
              "name": "XIN HUI QU",
              "code": 3
            },
            {
              "name": "TAI SHAN SHI",
              "code": 4
            },
            {
              "name": "KAI PING SHI",
              "code": 5
            },
            {
              "name": "HE SHAN SHI",
              "code": 6
            },
            {
              "name": "EN PING SHI",
              "code": 7
            }
          ]
        },
        {
          "name": "JIE YANG",
          "code": 9,
          "city": [
            {
              "name": "RONG CHENG QU",
              "code": 1
            },
            {
              "name": "PU NING SHI",
              "code": 2
            },
            {
              "name": "JIE DONG XIAN",
              "code": 3
            },
            {
              "name": "JIE XI XIAN",
              "code": 4
            },
            {
              "name": "HUI LAI XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "MAO MING",
          "code": 10,
          "city": [
            {
              "name": "MAO NAN QU",
              "code": 1
            },
            {
              "name": "MAO GANG QU",
              "code": 2
            },
            {
              "name": "GAO ZHOU SHI",
              "code": 3
            },
            {
              "name": "HUA ZHOU SHI",
              "code": 4
            },
            {
              "name": "XIN YI SHI",
              "code": 5
            },
            {
              "name": "DIAN BAI XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "MEI ZHOU",
          "code": 11,
          "city": [
            {
              "name": "MEI XIAN",
              "code": 1
            },
            {
              "name": "MEI JIANG QU",
              "code": 2
            },
            {
              "name": "XING NING SHI",
              "code": 3
            },
            {
              "name": "DA BU XIAN",
              "code": 4
            },
            {
              "name": "FENG SHUN XIAN",
              "code": 5
            },
            {
              "name": "WU HUA XIAN",
              "code": 6
            },
            {
              "name": "PING YUAN XIAN",
              "code": 7
            },
            {
              "name": "JIAO LING XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "QING YUAN",
          "code": 12,
          "city": [
            {
              "name": "QING CHENG QU",
              "code": 1
            },
            {
              "name": "YING DE SHI",
              "code": 2
            },
            {
              "name": "LIAN ZHOU SHI",
              "code": 3
            },
            {
              "name": "FO GANG XIAN",
              "code": 4
            },
            {
              "name": "YANG SHAN XIAN",
              "code": 5
            },
            {
              "name": "QING XIN XIAN",
              "code": 6
            },
            {
              "name": "LIAN SHAN",
              "code": 7
            },
            {
              "name": "LIAN NAN",
              "code": 8
            }
          ]
        },
        {
          "name": "SHAN TOU",
          "code": 13,
          "city": [
            {
              "name": "NAN AO XIAN",
              "code": 1
            },
            {
              "name": "CHAO YANG QU",
              "code": 2
            },
            {
              "name": "CHENG HAI QU",
              "code": 3
            },
            {
              "name": "LONG HU QU",
              "code": 4
            },
            {
              "name": "JIN PING QU",
              "code": 5
            },
            {
              "name": "HAO JIANG QU",
              "code": 6
            },
            {
              "name": "CHAO NAN QU",
              "code": 7
            }
          ]
        },
        {
          "name": "SHAN WEI",
          "code": 14,
          "city": [
            {
              "name": "CHENG QU",
              "code": 1
            },
            {
              "name": "LU FENG SHI",
              "code": 2
            },
            {
              "name": "HAI FENG XIAN",
              "code": 3
            },
            {
              "name": "LU HE XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "SHAO GUAN",
          "code": 15,
          "city": [
            {
              "name": "QU JIANG XIAN",
              "code": 1
            },
            {
              "name": "ZHEN JIANG QU",
              "code": 2
            },
            {
              "name": "WU JIANG QU",
              "code": 3
            },
            {
              "name": "QU JIANG QU",
              "code": 4
            },
            {
              "name": "LE CHANG SHI",
              "code": 5
            },
            {
              "name": "NAN XIONG SHI",
              "code": 6
            },
            {
              "name": "SHI XING XIAN",
              "code": 7
            },
            {
              "name": "REN HUA XIAN",
              "code": 8
            },
            {
              "name": "WENG YUAN XIAN",
              "code": 9
            },
            {
              "name": "XIN FENG XIAN",
              "code": 10
            },
            {
              "name": "RU YUAN",
              "code": 11
            }
          ]
        },
        {
          "name": "YANG JIANG",
          "code": 16,
          "city": [
            {
              "name": "JIANG CHENG QU",
              "code": 1
            },
            {
              "name": "YANG CHUN SHI",
              "code": 2
            },
            {
              "name": "YANG XI XIAN",
              "code": 3
            },
            {
              "name": "YANG DONG XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "YUN FU",
          "code": 17,
          "city": [
            {
              "name": "YUN CHENG QU",
              "code": 1
            },
            {
              "name": "LUO DING SHI",
              "code": 2
            },
            {
              "name": "XIN XING XIAN",
              "code": 3
            },
            {
              "name": "YU NAN XIAN",
              "code": 4
            },
            {
              "name": "YUN AN XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "ZHAN JIANG",
          "code": 18,
          "city": [
            {
              "name": "CHI KAN QU",
              "code": 1
            },
            {
              "name": "XIA SHAN QU",
              "code": 2
            },
            {
              "name": "PO TOU QU",
              "code": 3
            },
            {
              "name": "MA ZHANG QU",
              "code": 4
            },
            {
              "name": "LIAN JIANG SHI",
              "code": 5
            },
            {
              "name": "LEI ZHOU SHI",
              "code": 6
            },
            {
              "name": "WU CHUAN SHI",
              "code": 7
            },
            {
              "name": "SUI XI XIAN",
              "code": 8
            },
            {
              "name": "XU WEN XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "ZHAO QING",
          "code": 19,
          "city": [
            {
              "name": "ZHAO QING SHI",
              "code": 1
            },
            {
              "name": "GAO YAO SHI",
              "code": 2
            },
            {
              "name": "SI HUI SHI",
              "code": 3
            },
            {
              "name": "GUANG NING XIAN",
              "code": 4
            },
            {
              "name": "HUAI JI XIAN",
              "code": 5
            },
            {
              "name": "FENG KAI XIAN",
              "code": 6
            },
            {
              "name": "DE QING XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "ZHONG SHAN",
          "code": 20,
          "city": [
            {
              "name": "SHI QI JIE DAO",
              "code": 1
            },
            {
              "name": "DONG QU JIE DAO",
              "code": 2
            },
            {
              "name": "XI QU JIE DAO",
              "code": 3
            },
            {
              "name": "HUAN CHENG JIE DAO",
              "code": 4
            },
            {
              "name": "ZHONG SHAN GANG JIE DAO",
              "code": 5
            },
            {
              "name": "WU GUI SHAN JIE DAO",
              "code": 6
            }
          ]
        },
        {
          "name": "ZHU HAI",
          "code": 21,
          "city": [
            {
              "name": "XIANG ZHOU QU",
              "code": 1
            },
            {
              "name": "DOU MEN QU",
              "code": 2
            },
            {
              "name": "JIN WAN QU",
              "code": 3
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "GUANG XI",
      "code": 6,
      "state": [
        {
          "name": "NAN NING",
          "code": 1,
          "city": [
            {
              "name": "YONG NING QU",
              "code": 1
            },
            {
              "name": "QING XIU QU",
              "code": 2
            },
            {
              "name": "XING NING QU",
              "code": 3
            },
            {
              "name": "LIANG QING QU",
              "code": 4
            },
            {
              "name": "XI XIANG TANG QU",
              "code": 5
            },
            {
              "name": "JIANG NAN QU",
              "code": 6
            },
            {
              "name": "WU MING XIAN",
              "code": 7
            },
            {
              "name": "LONG AN XIAN",
              "code": 8
            },
            {
              "name": "MA SHAN XIAN",
              "code": 9
            },
            {
              "name": "SHANG LIN XIAN",
              "code": 10
            },
            {
              "name": "BIN YANG XIAN",
              "code": 11
            },
            {
              "name": "HENG XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "GUI LIN",
          "code": 2,
          "city": [
            {
              "name": "XIU FENG QU",
              "code": 1
            },
            {
              "name": "DIE CAI QU",
              "code": 2
            },
            {
              "name": "XIANG SHAN QU",
              "code": 3
            },
            {
              "name": "QI XING QU",
              "code": 4
            },
            {
              "name": "YAN SHAN QU",
              "code": 5
            },
            {
              "name": "YANG SHUO XIAN",
              "code": 6
            },
            {
              "name": "LIN GUI XIAN",
              "code": 7
            },
            {
              "name": "LING CHUAN XIAN",
              "code": 8
            },
            {
              "name": "QUAN ZHOU XIAN",
              "code": 9
            },
            {
              "name": "PING LE XIAN",
              "code": 10
            },
            {
              "name": "XING AN XIAN",
              "code": 11
            },
            {
              "name": "GUAN YANG XIAN",
              "code": 12
            },
            {
              "name": "LI PU XIAN",
              "code": 13
            },
            {
              "name": "ZI YUAN XIAN",
              "code": 14
            },
            {
              "name": "YONG FU XIAN",
              "code": 15
            },
            {
              "name": "LONG SHENG",
              "code": 16
            },
            {
              "name": "GONG CHENG",
              "code": 17
            }
          ]
        },
        {
          "name": "BAI SE",
          "code": 3,
          "city": [
            {
              "name": "YOU JIANG QU",
              "code": 1
            },
            {
              "name": "LING YUN XIAN",
              "code": 2
            },
            {
              "name": "PING GUO XIAN",
              "code": 3
            },
            {
              "name": "XI LIN XIAN",
              "code": 4
            },
            {
              "name": "LE YE XIAN",
              "code": 5
            },
            {
              "name": "DE BAO XIAN",
              "code": 6
            },
            {
              "name": "TIAN LIN XIAN",
              "code": 7
            },
            {
              "name": "TIAN YANG XIAN",
              "code": 8
            },
            {
              "name": "JING XI XIAN",
              "code": 9
            },
            {
              "name": "TIAN DONG XIAN",
              "code": 10
            },
            {
              "name": "NA PO XIAN",
              "code": 11
            },
            {
              "name": "LONG LIN",
              "code": 12
            }
          ]
        },
        {
          "name": "BEI HAI",
          "code": 4,
          "city": [
            {
              "name": "HAI CHENG QU",
              "code": 1
            },
            {
              "name": "YIN HAI QU",
              "code": 2
            },
            {
              "name": "TIE SHAN GANG QU",
              "code": 3
            },
            {
              "name": "HE PU XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "CHONG ZUO",
          "code": 5,
          "city": [
            {
              "name": "JIANG ZHOU QU",
              "code": 1
            },
            {
              "name": "PING XIANG SHI",
              "code": 2
            },
            {
              "name": "NING MING XIAN",
              "code": 3
            },
            {
              "name": "FU SUI XIAN",
              "code": 4
            },
            {
              "name": "LONG ZHOU XIAN",
              "code": 5
            },
            {
              "name": "DA XIN XIAN",
              "code": 6
            },
            {
              "name": "TIAN DENG XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "FANG CHENG GANG",
          "code": 6,
          "city": [
            {
              "name": "GANG KOU QU",
              "code": 1
            },
            {
              "name": "FANG CHENG QU",
              "code": 2
            },
            {
              "name": "DONG XING SHI",
              "code": 3
            },
            {
              "name": "SHANG SI XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "GUI GANG",
          "code": 7,
          "city": [
            {
              "name": "GANG BEI QU",
              "code": 1
            },
            {
              "name": "GANG NAN QU",
              "code": 2
            },
            {
              "name": "TAN TANG QU",
              "code": 3
            },
            {
              "name": "GUI PING SHI",
              "code": 4
            },
            {
              "name": "PING NAN XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "HE CHI",
          "code": 8,
          "city": [
            {
              "name": "JIN CHENG JIANG QU",
              "code": 1
            },
            {
              "name": "YI ZHOU SHI",
              "code": 2
            },
            {
              "name": "TIAN E XIAN",
              "code": 3
            },
            {
              "name": "FENG SHAN XIAN",
              "code": 4
            },
            {
              "name": "NAN DAN XIAN",
              "code": 5
            },
            {
              "name": "DONG LAN XIAN",
              "code": 6
            },
            {
              "name": "DU AN",
              "code": 7
            },
            {
              "name": "LUO CHENG",
              "code": 8
            },
            {
              "name": "BA MA",
              "code": 9
            },
            {
              "name": "HUAN JIANG",
              "code": 10
            },
            {
              "name": "DA HUA",
              "code": 11
            }
          ]
        },
        {
          "name": "HE ZHOU",
          "code": 9,
          "city": [
            {
              "name": "BA BU QU",
              "code": 1
            },
            {
              "name": "ZHONG SHAN XIAN",
              "code": 2
            },
            {
              "name": "ZHAO PING XIAN",
              "code": 3
            },
            {
              "name": "FU CHUAN",
              "code": 4
            }
          ]
        },
        {
          "name": "LAI BIN",
          "code": 10,
          "city": [
            {
              "name": "XING BIN QU",
              "code": 1
            },
            {
              "name": "HE SHAN SHI",
              "code": 2
            },
            {
              "name": "XIANG ZHOU XIAN",
              "code": 3
            },
            {
              "name": "WU XUAN XIAN",
              "code": 4
            },
            {
              "name": "XIN CHENG XIAN",
              "code": 5
            },
            {
              "name": "JIN XIU",
              "code": 6
            }
          ]
        },
        {
          "name": "LIU ZHOU",
          "code": 11,
          "city": [
            {
              "name": "CHENG ZHONG QU",
              "code": 1
            },
            {
              "name": "YU FENG QU",
              "code": 2
            },
            {
              "name": "LIU BEI QU",
              "code": 3
            },
            {
              "name": "LIU NAN QU",
              "code": 4
            },
            {
              "name": "LIU JIANG XIAN",
              "code": 5
            },
            {
              "name": "LIU CHENG XIAN",
              "code": 6
            },
            {
              "name": "LU ZHAI XIAN",
              "code": 7
            },
            {
              "name": "RONG AN XIAN",
              "code": 8
            },
            {
              "name": "RONG SHUI",
              "code": 9
            },
            {
              "name": "SAN JIANG",
              "code": 10
            }
          ]
        },
        {
          "name": "QIN ZHOU",
          "code": 12,
          "city": [
            {
              "name": "QIN NAN QU",
              "code": 1
            },
            {
              "name": "QIN BEI QU",
              "code": 2
            },
            {
              "name": "LING SHAN XIAN",
              "code": 3
            },
            {
              "name": "PU BEI XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "WU ZHOU",
          "code": 13,
          "city": [
            {
              "name": "WAN XIU QU",
              "code": 1
            },
            {
              "name": "DIE SHAN QU",
              "code": 2
            },
            {
              "name": "CHANG ZHOU QU",
              "code": 3
            },
            {
              "name": "CEN XI SHI",
              "code": 4
            },
            {
              "name": "CANG WU XIAN",
              "code": 5
            },
            {
              "name": "TENG XIAN",
              "code": 6
            },
            {
              "name": "MENG SHAN XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "YU LIN",
          "code": 14,
          "city": [
            {
              "name": "YU ZHOU QU",
              "code": 1
            },
            {
              "name": "BEI LIU SHI",
              "code": 2
            },
            {
              "name": "RONG XIAN",
              "code": 3
            },
            {
              "name": "LU CHUAN XIAN",
              "code": 4
            },
            {
              "name": "BO BAI XIAN",
              "code": 5
            },
            {
              "name": "XING YE XIAN",
              "code": 6
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "GUI ZHOU",
      "code": 7,
      "state": [
        {
          "name": "GUI YANG",
          "code": 1,
          "city": [
            {
              "name": "NAN MING QU",
              "code": 1
            },
            {
              "name": "YUN YAN QU",
              "code": 2
            },
            {
              "name": "HUA XI QU",
              "code": 3
            },
            {
              "name": "WU DANG QU",
              "code": 4
            },
            {
              "name": "BAI YUN QU",
              "code": 5
            },
            {
              "name": "XIAO HE QU",
              "code": 6
            },
            {
              "name": "JIN YANG XIN QU",
              "code": 7
            },
            {
              "name": "XIN TIAN YUAN QU",
              "code": 8
            },
            {
              "name": "QING ZHEN SHI",
              "code": 9
            },
            {
              "name": "KAI YANG XIAN",
              "code": 10
            },
            {
              "name": "XIU WEN XIAN",
              "code": 11
            },
            {
              "name": "XI FENG XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "AN SHUN",
          "code": 2,
          "city": [
            {
              "name": "XI XIU QU",
              "code": 1
            },
            {
              "name": "GUAN LING",
              "code": 2
            },
            {
              "name": "ZHEN NING",
              "code": 3
            },
            {
              "name": "ZI YUN",
              "code": 4
            },
            {
              "name": "PING BA XIAN",
              "code": 5
            },
            {
              "name": "PU DING XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "BI JIE",
          "code": 3,
          "city": [
            {
              "name": "BI JIE SHI",
              "code": 1
            },
            {
              "name": "DA FANG XIAN",
              "code": 2
            },
            {
              "name": "QIAN XI XIAN",
              "code": 3
            },
            {
              "name": "JIN SHA XIAN",
              "code": 4
            },
            {
              "name": "ZHI JIN XIAN",
              "code": 5
            },
            {
              "name": "NA YONG XIAN",
              "code": 6
            },
            {
              "name": "HE ZHANG XIAN",
              "code": 7
            },
            {
              "name": "WEI NING",
              "code": 8
            }
          ]
        },
        {
          "name": "LIU PAN SHUI",
          "code": 4,
          "city": [
            {
              "name": "ZHONG SHAN QU",
              "code": 1
            },
            {
              "name": "LU ZHI TE QU",
              "code": 2
            },
            {
              "name": "SHUI CHENG XIAN",
              "code": 3
            },
            {
              "name": "PAN XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "QIAN DONG NAN",
          "code": 5,
          "city": [
            {
              "name": "KAI LI SHI",
              "code": 1
            },
            {
              "name": "HUANG PING XIAN",
              "code": 2
            },
            {
              "name": "SHI BING XIAN",
              "code": 3
            },
            {
              "name": "SAN SUI XIAN",
              "code": 4
            },
            {
              "name": "ZHEN YUAN XIAN",
              "code": 5
            },
            {
              "name": "CEN GONG XIAN",
              "code": 6
            },
            {
              "name": "TIAN ZHU XIAN",
              "code": 7
            },
            {
              "name": "JIN PING XIAN",
              "code": 8
            },
            {
              "name": "JIAN HE XIAN",
              "code": 9
            },
            {
              "name": "TAI JIANG XIAN",
              "code": 10
            },
            {
              "name": "LI PING XIAN",
              "code": 11
            },
            {
              "name": "RONG JIANG XIAN",
              "code": 12
            },
            {
              "name": "CONG JIANG XIAN",
              "code": 13
            },
            {
              "name": "LEI SHAN XIAN",
              "code": 14
            },
            {
              "name": "MA JIANG XIAN",
              "code": 15
            },
            {
              "name": "DAN ZHAI XIAN",
              "code": 16
            }
          ]
        },
        {
          "name": "QIAN NAN",
          "code": 6,
          "city": [
            {
              "name": "DU YUN SHI",
              "code": 1
            },
            {
              "name": "FU QUAN SHI",
              "code": 2
            },
            {
              "name": "LI BO XIAN",
              "code": 3
            },
            {
              "name": "GUI DING XIAN",
              "code": 4
            },
            {
              "name": "WENG AN XIAN",
              "code": 5
            },
            {
              "name": "DU SHAN XIAN",
              "code": 6
            },
            {
              "name": "PING TANG XIAN",
              "code": 7
            },
            {
              "name": "LUO DIAN XIAN",
              "code": 8
            },
            {
              "name": "CHANG SHUN XIAN",
              "code": 9
            },
            {
              "name": "LONG LI XIAN",
              "code": 10
            },
            {
              "name": "HUI SHUI XIAN",
              "code": 11
            },
            {
              "name": "SAN DU",
              "code": 12
            }
          ]
        },
        {
          "name": "QIAN XI NAN",
          "code": 7,
          "city": [
            {
              "name": "XING YI SHI",
              "code": 1
            },
            {
              "name": "XING REN XIAN",
              "code": 2
            },
            {
              "name": "PU AN XIAN",
              "code": 3
            },
            {
              "name": "QING LONG XIAN",
              "code": 4
            },
            {
              "name": "ZHEN FENG XIAN",
              "code": 5
            },
            {
              "name": "WANG MO XIAN",
              "code": 6
            },
            {
              "name": "CE HENG XIAN",
              "code": 7
            },
            {
              "name": "AN LONG XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "TONG REN",
          "code": 8,
          "city": [
            {
              "name": "TONG REN SHI",
              "code": 1
            },
            {
              "name": "JIANG KOU XIAN",
              "code": 2
            },
            {
              "name": "SHI QIAN XIAN",
              "code": 3
            },
            {
              "name": "SI NAN XIAN",
              "code": 4
            },
            {
              "name": "DE JIANG XIAN",
              "code": 5
            },
            {
              "name": "YU PING",
              "code": 6
            },
            {
              "name": "YIN JIANG",
              "code": 7
            },
            {
              "name": "YAN HE",
              "code": 8
            },
            {
              "name": "SONG TAO",
              "code": 9
            },
            {
              "name": "WAN SHAN TE QU",
              "code": 10
            }
          ]
        },
        {
          "name": "ZUN YI",
          "code": 9,
          "city": [
            {
              "name": "HONG HUA GANG QU",
              "code": 1
            },
            {
              "name": "WU CHUAN XIAN",
              "code": 2
            },
            {
              "name": "DAO ZHEN XIAN",
              "code": 3
            },
            {
              "name": "HUI CHUAN QU",
              "code": 4
            },
            {
              "name": "CHI SHUI SHI",
              "code": 5
            },
            {
              "name": "REN HUAI SHI",
              "code": 6
            },
            {
              "name": "ZUN YI XIAN",
              "code": 7
            },
            {
              "name": "TONG ZI XIAN",
              "code": 8
            },
            {
              "name": "SUI YANG XIAN",
              "code": 9
            },
            {
              "name": "ZHENG AN XIAN",
              "code": 10
            },
            {
              "name": "FENG GANG XIAN",
              "code": 11
            },
            {
              "name": "MEI TAN XIAN",
              "code": 12
            },
            {
              "name": "YU QING XIAN",
              "code": 13
            },
            {
              "name": "XI SHUI XIAN",
              "code": 14
            },
            {
              "name": "DAO ZHEN",
              "code": 15
            },
            {
              "name": "WU CHUAN",
              "code": 16
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "HAI NAN",
      "code": 8,
      "state": [
        {
          "name": "HAI KOU",
          "code": 1,
          "city": [
            {
              "name": "XIU YING QU",
              "code": 1
            },
            {
              "name": "LONG HUA QU",
              "code": 2
            },
            {
              "name": "QIONG SHAN QU",
              "code": 3
            },
            {
              "name": "MEI LAN QU",
              "code": 4
            }
          ]
        },
        {
          "name": "SAN YA",
          "code": 2,
          "city": []
        },
        {
          "name": "BAI SHA",
          "code": 3,
          "city": []
        },
        {
          "name": "BAO TING",
          "code": 4,
          "city": []
        },
        {
          "name": "CHANG JIANG",
          "code": 5,
          "city": []
        },
        {
          "name": "CHENG MAI XIAN",
          "code": 6,
          "city": []
        },
        {
          "name": "DING AN XIAN",
          "code": 7,
          "city": []
        },
        {
          "name": "DONG FANG",
          "code": 8,
          "city": []
        },
        {
          "name": "LE DONG",
          "code": 9,
          "city": []
        },
        {
          "name": "LIN GAO XIAN",
          "code": 10,
          "city": []
        },
        {
          "name": "LING SHUI",
          "code": 11,
          "city": []
        },
        {
          "name": "QIONG HAI",
          "code": 12,
          "city": []
        },
        {
          "name": "QIONG ZHONG",
          "code": 13,
          "city": []
        },
        {
          "name": "TUN CHANG XIAN",
          "code": 14,
          "city": []
        },
        {
          "name": "WAN NING",
          "code": 15,
          "city": []
        },
        {
          "name": "WEN CHANG",
          "code": 16,
          "city": []
        },
        {
          "name": "WU ZHI SHAN",
          "code": 17,
          "city": []
        },
        {
          "name": "DAN ZHOU",
          "code": 18,
          "city": [
            {
              "name": "SHI QU",
              "code": 1
            },
            {
              "name": "YANG PU KAI FA QU",
              "code": 2
            },
            {
              "name": "NA DA ZHEN",
              "code": 3
            },
            {
              "name": "WANG WU ZHEN",
              "code": 4
            },
            {
              "name": "YA XING ZHEN",
              "code": 5
            },
            {
              "name": "DA CHENG ZHEN",
              "code": 6
            },
            {
              "name": "ZHONG HE ZHEN",
              "code": 7
            },
            {
              "name": "E MAN ZHEN",
              "code": 8
            },
            {
              "name": "NAN FENG ZHEN",
              "code": 9
            },
            {
              "name": "BAI MA JING ZHEN",
              "code": 10
            },
            {
              "name": "LAN YANG ZHEN",
              "code": 11
            },
            {
              "name": "HE QING ZHEN",
              "code": 12
            },
            {
              "name": "HAI TOU ZHEN",
              "code": 13
            },
            {
              "name": "PAI PU ZHEN",
              "code": 14
            },
            {
              "name": "DONG CHENG ZHEN",
              "code": 15
            },
            {
              "name": "GUANG CUN ZHEN",
              "code": 16
            },
            {
              "name": "MU TANG ZHEN",
              "code": 17
            },
            {
              "name": "XIN ZHOU ZHEN",
              "code": 18
            },
            {
              "name": "SAN DU ZHEN",
              "code": 19
            },
            {
              "name": "QI TA",
              "code": 20
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "HE BEI",
      "code": 9,
      "state": [
        {
          "name": "SHI JIA ZHUANG",
          "code": 1,
          "city": [
            {
              "name": "CHANG AN QU",
              "code": 1
            },
            {
              "name": "QIAO DONG QU",
              "code": 2
            },
            {
              "name": "QIAO XI QU",
              "code": 3
            },
            {
              "name": "XIN HUA QU",
              "code": 4
            },
            {
              "name": "YU HUA QU",
              "code": 5
            },
            {
              "name": "JING XING KUANG QU",
              "code": 6
            },
            {
              "name": "GAO XIN QU",
              "code": 7
            },
            {
              "name": "XIN JI SHI",
              "code": 8
            },
            {
              "name": "GAO CHENG SHI",
              "code": 9
            },
            {
              "name": "JIN ZHOU SHI",
              "code": 10
            },
            {
              "name": "XIN LE SHI",
              "code": 11
            },
            {
              "name": "LU QUAN SHI",
              "code": 12
            },
            {
              "name": "JING XING XIAN",
              "code": 13
            },
            {
              "name": "ZHENG DING XIAN",
              "code": 14
            },
            {
              "name": "LUAN CHENG XIAN",
              "code": 15
            },
            {
              "name": "XING TANG XIAN",
              "code": 16
            },
            {
              "name": "LING SHOU XIAN",
              "code": 17
            },
            {
              "name": "GAO YI XIAN",
              "code": 18
            },
            {
              "name": "SHEN ZE XIAN",
              "code": 19
            },
            {
              "name": "ZAN HUANG XIAN",
              "code": 20
            },
            {
              "name": "WU JI XIAN",
              "code": 21
            },
            {
              "name": "PING SHAN XIAN",
              "code": 22
            },
            {
              "name": "YUAN SHI XIAN",
              "code": 23
            },
            {
              "name": "ZHAO XIAN",
              "code": 24
            }
          ]
        },
        {
          "name": "BAO DING",
          "code": 2,
          "city": [
            {
              "name": "XIN SHI QU",
              "code": 1
            },
            {
              "name": "NAN SHI QU",
              "code": 2
            },
            {
              "name": "BEI SHI QU",
              "code": 3
            },
            {
              "name": "ZHUO ZHOU SHI",
              "code": 4
            },
            {
              "name": "DING ZHOU SHI",
              "code": 5
            },
            {
              "name": "AN GUO SHI",
              "code": 6
            },
            {
              "name": "GAO BEI DIAN SHI",
              "code": 7
            },
            {
              "name": "MAN CHENG XIAN",
              "code": 8
            },
            {
              "name": "QING YUAN XIAN",
              "code": 9
            },
            {
              "name": "LAI SHUI XIAN",
              "code": 10
            },
            {
              "name": "FU PING XIAN",
              "code": 11
            },
            {
              "name": "XU SHUI XIAN",
              "code": 12
            },
            {
              "name": "DING XING XIAN",
              "code": 13
            },
            {
              "name": "TANG XIAN",
              "code": 14
            },
            {
              "name": "GAO YANG XIAN",
              "code": 15
            },
            {
              "name": "RONG CHENG XIAN",
              "code": 16
            },
            {
              "name": "LAI YUAN XIAN",
              "code": 17
            },
            {
              "name": "WANG DU XIAN",
              "code": 18
            },
            {
              "name": "AN XIN XIAN",
              "code": 19
            },
            {
              "name": "YI XIAN",
              "code": 20
            },
            {
              "name": "QU YANG XIAN",
              "code": 21
            },
            {
              "name": "LI XIAN",
              "code": 22
            },
            {
              "name": "SHUN PING XIAN",
              "code": 23
            },
            {
              "name": "BO YE XIAN",
              "code": 24
            },
            {
              "name": "XIONG XIAN",
              "code": 25
            }
          ]
        },
        {
          "name": "CANG ZHOU",
          "code": 3,
          "city": [
            {
              "name": "YUN HE QU",
              "code": 1
            },
            {
              "name": "XIN HUA QU",
              "code": 2
            },
            {
              "name": "BO TOU SHI",
              "code": 3
            },
            {
              "name": "REN QIU SHI",
              "code": 4
            },
            {
              "name": "HUANG HUA SHI",
              "code": 5
            },
            {
              "name": "HE JIAN SHI",
              "code": 6
            },
            {
              "name": "CANG XIAN",
              "code": 7
            },
            {
              "name": "QING XIAN",
              "code": 8
            },
            {
              "name": "DONG GUANG XIAN",
              "code": 9
            },
            {
              "name": "HAI XING XIAN",
              "code": 10
            },
            {
              "name": "YAN SHAN XIAN",
              "code": 11
            },
            {
              "name": "SU NING XIAN",
              "code": 12
            },
            {
              "name": "NAN PI XIAN",
              "code": 13
            },
            {
              "name": "WU QIAO XIAN",
              "code": 14
            },
            {
              "name": "XIAN XIAN",
              "code": 15
            },
            {
              "name": "MENG CUN",
              "code": 16
            }
          ]
        },
        {
          "name": "CHENG DE",
          "code": 4,
          "city": [
            {
              "name": "SHUANG QIAO QU",
              "code": 1
            },
            {
              "name": "SHUANG LUAN QU",
              "code": 2
            },
            {
              "name": "YING SHOU YING ZI KUANG QU",
              "code": 3
            },
            {
              "name": "CHENG DE XIAN",
              "code": 4
            },
            {
              "name": "XING LONG XIAN",
              "code": 5
            },
            {
              "name": "PING QUAN XIAN",
              "code": 6
            },
            {
              "name": "LUAN PING XIAN",
              "code": 7
            },
            {
              "name": "LONG HUA XIAN",
              "code": 8
            },
            {
              "name": "FENG NING",
              "code": 9
            },
            {
              "name": "KUAN CHENG",
              "code": 10
            },
            {
              "name": "WEI CHANG",
              "code": 11
            }
          ]
        },
        {
          "name": "HAN DAN",
          "code": 5,
          "city": [
            {
              "name": "CONG TAI QU",
              "code": 1
            },
            {
              "name": "FU XING QU",
              "code": 2
            },
            {
              "name": "HAN SHAN QU",
              "code": 3
            },
            {
              "name": "FENG FENG KUANG QU",
              "code": 4
            },
            {
              "name": "WU AN SHI",
              "code": 5
            },
            {
              "name": "HAN DAN XIAN",
              "code": 6
            },
            {
              "name": "LIN ZHANG XIAN",
              "code": 7
            },
            {
              "name": "CHENG AN XIAN",
              "code": 8
            },
            {
              "name": "DA MING XIAN",
              "code": 9
            },
            {
              "name": "SHE XIAN",
              "code": 10
            },
            {
              "name": "CI XIAN",
              "code": 11
            },
            {
              "name": "FEI XIANG XIAN",
              "code": 12
            },
            {
              "name": "YONG NIAN XIAN",
              "code": 13
            },
            {
              "name": "QIU XIAN",
              "code": 14
            },
            {
              "name": "JI ZE XIAN",
              "code": 15
            },
            {
              "name": "GUANG PING XIAN",
              "code": 16
            },
            {
              "name": "GUAN TAO XIAN",
              "code": 17
            },
            {
              "name": "WEI XIAN",
              "code": 18
            },
            {
              "name": "QU ZHOU XIAN",
              "code": 19
            }
          ]
        },
        {
          "name": "HENG SHUI",
          "code": 6,
          "city": [
            {
              "name": "TAO CHENG QU",
              "code": 1
            },
            {
              "name": "JI ZHOU SHI",
              "code": 2
            },
            {
              "name": "SHEN ZHOU SHI",
              "code": 3
            },
            {
              "name": "ZAO QIANG XIAN",
              "code": 4
            },
            {
              "name": "WU YI XIAN",
              "code": 5
            },
            {
              "name": "WU QIANG XIAN",
              "code": 6
            },
            {
              "name": "RAO YANG XIAN",
              "code": 7
            },
            {
              "name": "AN PING XIAN",
              "code": 8
            },
            {
              "name": "GU CHENG XIAN",
              "code": 9
            },
            {
              "name": "JING XIAN",
              "code": 10
            },
            {
              "name": "FU CHENG XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "LANG FANG",
          "code": 7,
          "city": [
            {
              "name": "AN CI QU",
              "code": 1
            },
            {
              "name": "GUANG YANG QU",
              "code": 2
            },
            {
              "name": "BA ZHOU SHI",
              "code": 3
            },
            {
              "name": "SAN HE SHI",
              "code": 4
            },
            {
              "name": "GU AN XIAN",
              "code": 5
            },
            {
              "name": "YONG QING XIAN",
              "code": 6
            },
            {
              "name": "XIANG HE XIAN",
              "code": 7
            },
            {
              "name": "DAI CHENG XIAN",
              "code": 8
            },
            {
              "name": "WEN AN XIAN",
              "code": 9
            },
            {
              "name": "DA CHANG",
              "code": 10
            }
          ]
        },
        {
          "name": "QIN HUANG DAO",
          "code": 8,
          "city": [
            {
              "name": "HAI GANG QU",
              "code": 1
            },
            {
              "name": "SHAN HAI GUAN QU",
              "code": 2
            },
            {
              "name": "BEI DAI HE QU",
              "code": 3
            },
            {
              "name": "CHANG LI XIAN",
              "code": 4
            },
            {
              "name": "FU NING XIAN",
              "code": 5
            },
            {
              "name": "LU LONG XIAN",
              "code": 6
            },
            {
              "name": "QING LONG",
              "code": 7
            }
          ]
        },
        {
          "name": "TANG SHAN",
          "code": 9,
          "city": [
            {
              "name": "LU BEI QU",
              "code": 1
            },
            {
              "name": "LU NAN QU",
              "code": 2
            },
            {
              "name": "GU YE QU",
              "code": 3
            },
            {
              "name": "KAI PING QU",
              "code": 4
            },
            {
              "name": "FENG NAN QU",
              "code": 5
            },
            {
              "name": "FENG RUN QU",
              "code": 6
            },
            {
              "name": "ZUN HUA SHI",
              "code": 7
            },
            {
              "name": "QIAN AN SHI",
              "code": 8
            },
            {
              "name": "LUAN XIAN",
              "code": 9
            },
            {
              "name": "LUAN NAN XIAN",
              "code": 10
            },
            {
              "name": "LE TING XIAN",
              "code": 11
            },
            {
              "name": "QIAN XI XIAN",
              "code": 12
            },
            {
              "name": "YU TIAN XIAN",
              "code": 13
            },
            {
              "name": "TANG HAI XIAN",
              "code": 14
            }
          ]
        },
        {
          "name": "XING TAI",
          "code": 10,
          "city": [
            {
              "name": "QIAO DONG QU",
              "code": 1
            },
            {
              "name": "QIAO XI QU",
              "code": 2
            },
            {
              "name": "NAN GONG SHI",
              "code": 3
            },
            {
              "name": "SHA HE SHI",
              "code": 4
            },
            {
              "name": "XING TAI XIAN",
              "code": 5
            },
            {
              "name": "LIN CHENG XIAN",
              "code": 6
            },
            {
              "name": "NEI QIU XIAN",
              "code": 7
            },
            {
              "name": "BAI XIANG XIAN",
              "code": 8
            },
            {
              "name": "LONG YAO XIAN",
              "code": 9
            },
            {
              "name": "REN XIAN",
              "code": 10
            },
            {
              "name": "NAN HE XIAN",
              "code": 11
            },
            {
              "name": "NING JIN XIAN",
              "code": 12
            },
            {
              "name": "JU LU XIAN",
              "code": 13
            },
            {
              "name": "XIN HE XIAN",
              "code": 14
            },
            {
              "name": "GUANG ZONG XIAN",
              "code": 15
            },
            {
              "name": "PING XIANG XIAN",
              "code": 16
            },
            {
              "name": "WEI XIAN",
              "code": 17
            },
            {
              "name": "QING HE XIAN",
              "code": 18
            },
            {
              "name": "LIN XI XIAN",
              "code": 19
            }
          ]
        },
        {
          "name": "ZHANG JIA KOU",
          "code": 11,
          "city": [
            {
              "name": "QIAO XI QU",
              "code": 1
            },
            {
              "name": "QIAO DONG QU",
              "code": 2
            },
            {
              "name": "XUAN HUA QU",
              "code": 3
            },
            {
              "name": "XIA HUA YUAN QU",
              "code": 4
            },
            {
              "name": "XUAN HUA XIAN",
              "code": 5
            },
            {
              "name": "ZHANG BEI XIAN",
              "code": 6
            },
            {
              "name": "KANG BAO XIAN",
              "code": 7
            },
            {
              "name": "GU YUAN XIAN",
              "code": 8
            },
            {
              "name": "SHANG YI XIAN",
              "code": 9
            },
            {
              "name": "YU XIAN",
              "code": 10
            },
            {
              "name": "YANG YUAN XIAN",
              "code": 11
            },
            {
              "name": "HUAI AN XIAN",
              "code": 12
            },
            {
              "name": "WAN QUAN XIAN",
              "code": 13
            },
            {
              "name": "HUAI LAI XIAN",
              "code": 14
            },
            {
              "name": "ZHUO LU XIAN",
              "code": 15
            },
            {
              "name": "CHI CHENG XIAN",
              "code": 16
            },
            {
              "name": "CHONG LI XIAN",
              "code": 17
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "HE NAN",
      "code": 10,
      "state": [
        {
          "name": "ZHENG ZHOU",
          "code": 1,
          "city": [
            {
              "name": "JIN SHUI QU",
              "code": 1
            },
            {
              "name": "MANG SHAN QU",
              "code": 2
            },
            {
              "name": "ER QI QU",
              "code": 3
            },
            {
              "name": "GUAN CHENG QU",
              "code": 4
            },
            {
              "name": "ZHONG YUAN QU",
              "code": 5
            },
            {
              "name": "SHANG JIE QU",
              "code": 6
            },
            {
              "name": "HUI JI QU",
              "code": 7
            },
            {
              "name": "ZHENG DONG XIN QU",
              "code": 8
            },
            {
              "name": "JING JI JI SHU KAI FA QU",
              "code": 9
            },
            {
              "name": "GAO XIN KAI FA QU",
              "code": 10
            },
            {
              "name": "CHU KOU JIA GONG QU",
              "code": 11
            },
            {
              "name": "GONG YI SHI",
              "code": 12
            },
            {
              "name": "XING YANG SHI",
              "code": 13
            },
            {
              "name": "XIN MI SHI",
              "code": 14
            },
            {
              "name": "XIN ZHENG SHI",
              "code": 15
            },
            {
              "name": "DENG FENG SHI",
              "code": 16
            },
            {
              "name": "ZHONG MU XIAN",
              "code": 17
            }
          ]
        },
        {
          "name": "LUO YANG",
          "code": 2,
          "city": [
            {
              "name": "XI GONG QU",
              "code": 1
            },
            {
              "name": "LAO CHENG QU",
              "code": 2
            },
            {
              "name": "JIAN XI QU",
              "code": 3
            },
            {
              "name": "CHAN HE HUI ZU QU",
              "code": 4
            },
            {
              "name": "LUO LONG QU",
              "code": 5
            },
            {
              "name": "JI LI QU",
              "code": 6
            },
            {
              "name": "YAN SHI SHI",
              "code": 7
            },
            {
              "name": "MENG JIN XIAN",
              "code": 8
            },
            {
              "name": "XIN AN XIAN",
              "code": 9
            },
            {
              "name": "LUAN CHUAN XIAN",
              "code": 10
            },
            {
              "name": "SONG XIAN",
              "code": 11
            },
            {
              "name": "RU YANG XIAN",
              "code": 12
            },
            {
              "name": "YI YANG XIAN",
              "code": 13
            },
            {
              "name": "LUO NING XIAN",
              "code": 14
            },
            {
              "name": "YI CHUAN XIAN",
              "code": 15
            }
          ]
        },
        {
          "name": "KAI FENG",
          "code": 3,
          "city": [
            {
              "name": "GU LOU QU",
              "code": 1
            },
            {
              "name": "LONG TING QU",
              "code": 2
            },
            {
              "name": "SHUN HE HUI ZU QU",
              "code": 3
            },
            {
              "name": "JIN MING QU",
              "code": 4
            },
            {
              "name": "YU WANG TAI QU",
              "code": 5
            },
            {
              "name": "QI XIAN",
              "code": 6
            },
            {
              "name": "TONG XU XIAN",
              "code": 7
            },
            {
              "name": "WEI SHI XIAN",
              "code": 8
            },
            {
              "name": "KAI FENG XIAN",
              "code": 9
            },
            {
              "name": "LAN KAO XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "AN YANG",
          "code": 4,
          "city": [
            {
              "name": "BEI GUAN QU",
              "code": 1
            },
            {
              "name": "WEN FENG QU",
              "code": 2
            },
            {
              "name": "YIN DU QU",
              "code": 3
            },
            {
              "name": "LONG AN QU",
              "code": 4
            },
            {
              "name": "LIN ZHOU SHI",
              "code": 5
            },
            {
              "name": "AN YANG XIAN",
              "code": 6
            },
            {
              "name": "TANG YIN XIAN",
              "code": 7
            },
            {
              "name": "HUA XIAN",
              "code": 8
            },
            {
              "name": "NEI HUANG XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "HE BI",
          "code": 5,
          "city": [
            {
              "name": "QI BIN QU",
              "code": 1
            },
            {
              "name": "SHAN CHENG QU",
              "code": 2
            },
            {
              "name": "HE SHAN QU",
              "code": 3
            },
            {
              "name": "JUN XIAN",
              "code": 4
            },
            {
              "name": "QI XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "JI YUAN",
          "code": 6,
          "city": [
            {
              "name": "JI YUAN SHI",
              "code": 1
            }
          ]
        },
        {
          "name": "JIAO ZUO",
          "code": 7,
          "city": [
            {
              "name": "JIE FANG QU",
              "code": 1
            },
            {
              "name": "ZHONG ZHAN QU",
              "code": 2
            },
            {
              "name": "MA CUN QU",
              "code": 3
            },
            {
              "name": "SHAN YANG QU",
              "code": 4
            },
            {
              "name": "QIN YANG SHI",
              "code": 5
            },
            {
              "name": "MENG ZHOU SHI",
              "code": 6
            },
            {
              "name": "XIU WU XIAN",
              "code": 7
            },
            {
              "name": "BO AI XIAN",
              "code": 8
            },
            {
              "name": "WU ZHI XIAN",
              "code": 9
            },
            {
              "name": "WEN XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "NAN YANG",
          "code": 8,
          "city": [
            {
              "name": "WO LONG QU",
              "code": 1
            },
            {
              "name": "WAN CHENG QU",
              "code": 2
            },
            {
              "name": "DENG ZHOU SHI",
              "code": 3
            },
            {
              "name": "NAN ZHAO XIAN",
              "code": 4
            },
            {
              "name": "FANG CHENG XIAN",
              "code": 5
            },
            {
              "name": "XI XIA XIAN",
              "code": 6
            },
            {
              "name": "ZHEN PING XIAN",
              "code": 7
            },
            {
              "name": "NEI XIANG XIAN",
              "code": 8
            },
            {
              "name": "XI CHUAN XIAN",
              "code": 9
            },
            {
              "name": "SHE QI XIAN",
              "code": 10
            },
            {
              "name": "TANG HE XIAN",
              "code": 11
            },
            {
              "name": "XIN YE XIAN",
              "code": 12
            },
            {
              "name": "TONG BAI XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "PING DING SHAN",
          "code": 9,
          "city": [
            {
              "name": "XIN HUA QU",
              "code": 1
            },
            {
              "name": "WEI DONG QU",
              "code": 2
            },
            {
              "name": "ZHAN HE QU",
              "code": 3
            },
            {
              "name": "SHI LONG QU",
              "code": 4
            },
            {
              "name": "WU GANG SHI",
              "code": 5
            },
            {
              "name": "RU ZHOU SHI",
              "code": 6
            },
            {
              "name": "BAO FENG XIAN",
              "code": 7
            },
            {
              "name": "YE XIAN",
              "code": 8
            },
            {
              "name": "LU SHAN XIAN",
              "code": 9
            },
            {
              "name": "JIA XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "SAN MEN XIA",
          "code": 10,
          "city": [
            {
              "name": "HU BIN QU",
              "code": 1
            },
            {
              "name": "YI MA SHI",
              "code": 2
            },
            {
              "name": "LING BAO SHI",
              "code": 3
            },
            {
              "name": "MIAN CHI XIAN",
              "code": 4
            },
            {
              "name": "SHAN XIAN",
              "code": 5
            },
            {
              "name": "LU SHI XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "SHANG QIU",
          "code": 11,
          "city": [
            {
              "name": "LIANG YUAN QU",
              "code": 1
            },
            {
              "name": "SUI YANG QU",
              "code": 2
            },
            {
              "name": "YONG CHENG SHI",
              "code": 3
            },
            {
              "name": "MIN QUAN XIAN",
              "code": 4
            },
            {
              "name": "SUI XIAN",
              "code": 5
            },
            {
              "name": "NING LING XIAN",
              "code": 6
            },
            {
              "name": "YU CHENG XIAN",
              "code": 7
            },
            {
              "name": "ZHE CHENG XIAN",
              "code": 8
            },
            {
              "name": "XIA YI XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "XIN XIANG",
          "code": 12,
          "city": [
            {
              "name": "WEI BIN QU",
              "code": 1
            },
            {
              "name": "HONG QI QU",
              "code": 2
            },
            {
              "name": "FENG QUAN QU",
              "code": 3
            },
            {
              "name": "MU YE QU",
              "code": 4
            },
            {
              "name": "WEI HUI SHI",
              "code": 5
            },
            {
              "name": "HUI XIAN SHI",
              "code": 6
            },
            {
              "name": "XIN XIANG XIAN",
              "code": 7
            },
            {
              "name": "HUO JIA XIAN",
              "code": 8
            },
            {
              "name": "YUAN YANG XIAN",
              "code": 9
            },
            {
              "name": "YAN JIN XIAN",
              "code": 10
            },
            {
              "name": "FENG QIU XIAN",
              "code": 11
            },
            {
              "name": "CHANG YUAN XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "XIN YANG",
          "code": 13,
          "city": [
            {
              "name": "SHI HE QU",
              "code": 1
            },
            {
              "name": "PING QIAO QU",
              "code": 2
            },
            {
              "name": "LUO SHAN XIAN",
              "code": 3
            },
            {
              "name": "GUANG SHAN XIAN",
              "code": 4
            },
            {
              "name": "XIN XIAN",
              "code": 5
            },
            {
              "name": "SHANG CHENG XIAN",
              "code": 6
            },
            {
              "name": "GU SHI XIAN",
              "code": 7
            },
            {
              "name": "HUANG CHUAN XIAN",
              "code": 8
            },
            {
              "name": "HUAI BIN XIAN",
              "code": 9
            },
            {
              "name": "XI XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "XU CHANG",
          "code": 14,
          "city": [
            {
              "name": "WEI DU QU",
              "code": 1
            },
            {
              "name": "YU ZHOU SHI",
              "code": 2
            },
            {
              "name": "CHANG GE SHI",
              "code": 3
            },
            {
              "name": "XU CHANG XIAN",
              "code": 4
            },
            {
              "name": "YAN LING XIAN",
              "code": 5
            },
            {
              "name": "XIANG CHENG XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "ZHOU KOU",
          "code": 15,
          "city": [
            {
              "name": "CHUAN HUI QU",
              "code": 1
            },
            {
              "name": "XIANG CHENG SHI",
              "code": 2
            },
            {
              "name": "FU GOU XIAN",
              "code": 3
            },
            {
              "name": "XI HUA XIAN",
              "code": 4
            },
            {
              "name": "SHANG SHUI XIAN",
              "code": 5
            },
            {
              "name": "SHEN QIU XIAN",
              "code": 6
            },
            {
              "name": "DAN CHENG XIAN",
              "code": 7
            },
            {
              "name": "HUAI YANG XIAN",
              "code": 8
            },
            {
              "name": "TAI KANG XIAN",
              "code": 9
            },
            {
              "name": "LU YI XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "ZHU MA DIAN",
          "code": 16,
          "city": [
            {
              "name": "YI CHENG QU",
              "code": 1
            },
            {
              "name": "XI PING XIAN",
              "code": 2
            },
            {
              "name": "SHANG CAI XIAN",
              "code": 3
            },
            {
              "name": "PING YU XIAN",
              "code": 4
            },
            {
              "name": "ZHENG YANG XIAN",
              "code": 5
            },
            {
              "name": "QUE SHAN XIAN",
              "code": 6
            },
            {
              "name": "BI YANG XIAN",
              "code": 7
            },
            {
              "name": "RU NAN XIAN",
              "code": 8
            },
            {
              "name": "SUI PING XIAN",
              "code": 9
            },
            {
              "name": "XIN CAI XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "TA HE",
          "code": 17,
          "city": [
            {
              "name": "YAN CHENG QU",
              "code": 1
            },
            {
              "name": "YUAN HUI QU",
              "code": 2
            },
            {
              "name": "SHAO LING QU",
              "code": 3
            },
            {
              "name": "WU YANG XIAN",
              "code": 4
            },
            {
              "name": "LIN YING XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "PU YANG",
          "code": 18,
          "city": [
            {
              "name": "HUA LONG QU",
              "code": 1
            },
            {
              "name": "QING FENG XIAN",
              "code": 2
            },
            {
              "name": "NAN LE XIAN",
              "code": 3
            },
            {
              "name": "FAN XIAN",
              "code": 4
            },
            {
              "name": "TAI QIAN XIAN",
              "code": 5
            },
            {
              "name": "PU YANG XIAN",
              "code": 6
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "HEI LONG JIANG",
      "code": 11,
      "state": [
        {
          "name": "HA ER BIN",
          "code": 1,
          "city": [
            {
              "name": "DAO LI QU",
              "code": 1
            },
            {
              "name": "NAN GANG QU",
              "code": 2
            },
            {
              "name": "DONG LI QU",
              "code": 3
            },
            {
              "name": "PING FANG QU",
              "code": 4
            },
            {
              "name": "XIANG FANG QU",
              "code": 5
            },
            {
              "name": "TAI PING QU",
              "code": 6
            },
            {
              "name": "DAO WAI QU",
              "code": 7
            },
            {
              "name": "A CHENG QU",
              "code": 8
            },
            {
              "name": "HU LAN QU",
              "code": 9
            },
            {
              "name": "SONG BEI QU",
              "code": 10
            },
            {
              "name": "SHANG ZHI SHI",
              "code": 11
            },
            {
              "name": "SHUANG CHENG SHI",
              "code": 12
            },
            {
              "name": "WU CHANG SHI",
              "code": 13
            },
            {
              "name": "FANG ZHENG XIAN",
              "code": 14
            },
            {
              "name": "BIN XIAN",
              "code": 15
            },
            {
              "name": "YI LAN XIAN",
              "code": 16
            },
            {
              "name": "BA YAN XIAN",
              "code": 17
            },
            {
              "name": "TONG HE XIAN",
              "code": 18
            },
            {
              "name": "MU LAN XIAN",
              "code": 19
            },
            {
              "name": "YAN SHOU XIAN",
              "code": 20
            }
          ]
        },
        {
          "name": "DA QING",
          "code": 2,
          "city": [
            {
              "name": "SA ER TU QU",
              "code": 1
            },
            {
              "name": "HONG GANG QU",
              "code": 2
            },
            {
              "name": "LONG FENG QU",
              "code": 3
            },
            {
              "name": "RANG HU LU QU",
              "code": 4
            },
            {
              "name": "DA TONG QU",
              "code": 5
            },
            {
              "name": "ZHAO ZHOU XIAN",
              "code": 6
            },
            {
              "name": "ZHAO YUAN XIAN",
              "code": 7
            },
            {
              "name": "LIN DIAN XIAN",
              "code": 8
            },
            {
              "name": "DU ER BO TE",
              "code": 9
            }
          ]
        },
        {
          "name": "DA XING AN LING",
          "code": 3,
          "city": [
            {
              "name": "HU MA XIAN",
              "code": 1
            },
            {
              "name": "MO HE XIAN",
              "code": 2
            },
            {
              "name": "TA HE XIAN",
              "code": 3
            }
          ]
        },
        {
          "name": "HE GANG",
          "code": 4,
          "city": [
            {
              "name": "XING SHAN QU",
              "code": 1
            },
            {
              "name": "GONG NONG QU",
              "code": 2
            },
            {
              "name": "NAN SHAN QU",
              "code": 3
            },
            {
              "name": "XING AN QU",
              "code": 4
            },
            {
              "name": "XIANG YANG QU",
              "code": 5
            },
            {
              "name": "DONG SHAN QU",
              "code": 6
            },
            {
              "name": "LUO BEI XIAN",
              "code": 7
            },
            {
              "name": "SUI BIN XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "HEI HE",
          "code": 5,
          "city": [
            {
              "name": "AI HUI QU",
              "code": 1
            },
            {
              "name": "WU DA LIAN CHI SHI",
              "code": 2
            },
            {
              "name": "BEI AN SHI",
              "code": 3
            },
            {
              "name": "NEN JIANG XIAN",
              "code": 4
            },
            {
              "name": "XUN KE XIAN",
              "code": 5
            },
            {
              "name": "SUN WU XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "JI XI",
          "code": 6,
          "city": [
            {
              "name": "JI GUAN QU",
              "code": 1
            },
            {
              "name": "HENG SHAN QU",
              "code": 2
            },
            {
              "name": "CHENG ZI HE QU",
              "code": 3
            },
            {
              "name": "DI DAO QU",
              "code": 4
            },
            {
              "name": "LI SHU QU",
              "code": 5
            },
            {
              "name": "HU LIN SHI",
              "code": 6
            },
            {
              "name": "MI SHAN SHI",
              "code": 7
            },
            {
              "name": "JI DONG XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "JIA MU SI",
          "code": 7,
          "city": [
            {
              "name": "QIAN JIN QU",
              "code": 1
            },
            {
              "name": "JIAO QU",
              "code": 2
            },
            {
              "name": "XIANG YANG QU",
              "code": 3
            },
            {
              "name": "DONG FENG QU",
              "code": 4
            },
            {
              "name": "TONG JIANG SHI",
              "code": 5
            },
            {
              "name": "FU JIN SHI",
              "code": 6
            },
            {
              "name": "HUA NAN XIAN",
              "code": 7
            },
            {
              "name": "HUA CHUAN XIAN",
              "code": 8
            },
            {
              "name": "TANG YUAN XIAN",
              "code": 9
            },
            {
              "name": "FU YUAN XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "MU DAN JIANG",
          "code": 8,
          "city": [
            {
              "name": "AI MIN QU",
              "code": 1
            },
            {
              "name": "DONG AN QU",
              "code": 2
            },
            {
              "name": "YANG MING QU",
              "code": 3
            },
            {
              "name": "XI AN QU",
              "code": 4
            },
            {
              "name": "SUI FEN HE SHI",
              "code": 5
            },
            {
              "name": "HAI LIN SHI",
              "code": 6
            },
            {
              "name": "NING AN SHI",
              "code": 7
            },
            {
              "name": "MU LING SHI",
              "code": 8
            },
            {
              "name": "DONG NING XIAN",
              "code": 9
            },
            {
              "name": "LIN KOU XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "QI TAI HE",
          "code": 9,
          "city": [
            {
              "name": "TAO SHAN QU",
              "code": 1
            },
            {
              "name": "XIN XING QU",
              "code": 2
            },
            {
              "name": "QIE ZI HE QU",
              "code": 3
            },
            {
              "name": "BO LI XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "QI QI HA ER",
          "code": 10,
          "city": [
            {
              "name": "LONG SHA QU",
              "code": 1
            },
            {
              "name": "ANG ANG XI QU",
              "code": 2
            },
            {
              "name": "TIE FENG QU",
              "code": 3
            },
            {
              "name": "JIAN HUA QU",
              "code": 4
            },
            {
              "name": "FU LA ER JI QU",
              "code": 5
            },
            {
              "name": "NIAN ZI SHAN QU",
              "code": 6
            },
            {
              "name": "MEI LI SI DA WO ER QU",
              "code": 7
            },
            {
              "name": "NE HE SHI",
              "code": 8
            },
            {
              "name": "LONG JIANG XIAN",
              "code": 9
            },
            {
              "name": "YI AN XIAN",
              "code": 10
            },
            {
              "name": "TAI LAI XIAN",
              "code": 11
            },
            {
              "name": "GAN NAN XIAN",
              "code": 12
            },
            {
              "name": "FU YU XIAN",
              "code": 13
            },
            {
              "name": "KE SHAN XIAN",
              "code": 14
            },
            {
              "name": "KE DONG XIAN",
              "code": 15
            },
            {
              "name": "BAI QUAN XIAN",
              "code": 16
            }
          ]
        },
        {
          "name": "SHUANG YA SHAN",
          "code": 11,
          "city": [
            {
              "name": "JIAN SHAN QU",
              "code": 1
            },
            {
              "name": "LING DONG QU",
              "code": 2
            },
            {
              "name": "SI FANG TAI QU",
              "code": 3
            },
            {
              "name": "BAO SHAN QU",
              "code": 4
            },
            {
              "name": "JI XIAN XIAN",
              "code": 5
            },
            {
              "name": "YOU YI XIAN",
              "code": 6
            },
            {
              "name": "BAO QING XIAN",
              "code": 7
            },
            {
              "name": "RAO HE XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "SUI HUA",
          "code": 12,
          "city": [
            {
              "name": "BEI LIN QU",
              "code": 1
            },
            {
              "name": "AN DA SHI",
              "code": 2
            },
            {
              "name": "ZHAO DONG SHI",
              "code": 3
            },
            {
              "name": "HAI LUN SHI",
              "code": 4
            },
            {
              "name": "WANG KUI XIAN",
              "code": 5
            },
            {
              "name": "LAN XI XIAN",
              "code": 6
            },
            {
              "name": "QING GANG XIAN",
              "code": 7
            },
            {
              "name": "QING AN XIAN",
              "code": 8
            },
            {
              "name": "MING SHUI XIAN",
              "code": 9
            },
            {
              "name": "SUI LENG XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "YI CHUN",
          "code": 13,
          "city": [
            {
              "name": "YI CHUN QU",
              "code": 1
            },
            {
              "name": "DAI LING QU",
              "code": 2
            },
            {
              "name": "NAN CHA QU",
              "code": 3
            },
            {
              "name": "JIN SHAN ZHUN QU",
              "code": 4
            },
            {
              "name": "XI LIN QU",
              "code": 5
            },
            {
              "name": "MEI XI QU",
              "code": 6
            },
            {
              "name": "WU MA HE QU",
              "code": 7
            },
            {
              "name": "CUI LUAN QU",
              "code": 8
            },
            {
              "name": "YOU HAO QU",
              "code": 9
            },
            {
              "name": "SHANG GAN LING QU",
              "code": 10
            },
            {
              "name": "WU YING QU",
              "code": 11
            },
            {
              "name": "HONG XING QU",
              "code": 12
            },
            {
              "name": "XIN QING QU",
              "code": 13
            },
            {
              "name": "TANG WANG HE QU",
              "code": 14
            },
            {
              "name": "WU YI LING QU",
              "code": 15
            },
            {
              "name": "TIE LI SHI",
              "code": 16
            },
            {
              "name": "JIA YIN XIAN",
              "code": 17
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "HU BEI",
      "code": 12,
      "state": [
        {
          "name": "WU HAN",
          "code": 1,
          "city": [
            {
              "name": "JIANG AN QU",
              "code": 1
            },
            {
              "name": "WU CHANG QU",
              "code": 2
            },
            {
              "name": "JIANG HAN QU",
              "code": 3
            },
            {
              "name": "QIAO KOU QU",
              "code": 4
            },
            {
              "name": "HAN YANG QU",
              "code": 5
            },
            {
              "name": "QING SHAN QU",
              "code": 6
            },
            {
              "name": "HONG SHAN QU",
              "code": 7
            },
            {
              "name": "DONG XI HU QU",
              "code": 8
            },
            {
              "name": "HAN NAN QU",
              "code": 9
            },
            {
              "name": "CAI DIAN QU",
              "code": 10
            },
            {
              "name": "JIANG XIA QU",
              "code": 11
            },
            {
              "name": "HUANG PI QU",
              "code": 12
            },
            {
              "name": "XIN ZHOU QU",
              "code": 13
            },
            {
              "name": "JING JI KAI FA QU",
              "code": 14
            }
          ]
        },
        {
          "name": "XIAN TAO",
          "code": 2,
          "city": [
            {
              "name": "XIAN TAO SHI",
              "code": 1
            }
          ]
        },
        {
          "name": "E ZHOU",
          "code": 3,
          "city": [
            {
              "name": "E CHENG QU",
              "code": 1
            },
            {
              "name": "HUA RONG QU",
              "code": 2
            },
            {
              "name": "LIANG ZI HU QU",
              "code": 3
            }
          ]
        },
        {
          "name": "HUANG GANG",
          "code": 4,
          "city": [
            {
              "name": "HUANG ZHOU QU",
              "code": 1
            },
            {
              "name": "MA CHENG SHI",
              "code": 2
            },
            {
              "name": "WU XUE SHI",
              "code": 3
            },
            {
              "name": "TUAN FENG XIAN",
              "code": 4
            },
            {
              "name": "HONG AN XIAN",
              "code": 5
            },
            {
              "name": "LUO TIAN XIAN",
              "code": 6
            },
            {
              "name": "YING SHAN XIAN",
              "code": 7
            },
            {
              "name": "XI SHUI XIAN",
              "code": 8
            },
            {
              "name": "QI CHUN XIAN",
              "code": 9
            },
            {
              "name": "HUANG MEI XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "HUANG SHI",
          "code": 5,
          "city": [
            {
              "name": "HUANG SHI GANG QU",
              "code": 1
            },
            {
              "name": "XI SAI SHAN QU",
              "code": 2
            },
            {
              "name": "XIA LU QU",
              "code": 3
            },
            {
              "name": "TIE SHAN QU",
              "code": 4
            },
            {
              "name": "DA YE SHI",
              "code": 5
            },
            {
              "name": "YANG XIN XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "JING MEN",
          "code": 6,
          "city": [
            {
              "name": "DONG BAO QU",
              "code": 1
            },
            {
              "name": "DUO DAO QU",
              "code": 2
            },
            {
              "name": "ZHONG XIANG SHI",
              "code": 3
            },
            {
              "name": "JING SHAN XIAN",
              "code": 4
            },
            {
              "name": "SHA YANG XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "JING ZHOU",
          "code": 7,
          "city": [
            {
              "name": "SHA SHI QU",
              "code": 1
            },
            {
              "name": "JING ZHOU QU",
              "code": 2
            },
            {
              "name": "SHI SHOU SHI",
              "code": 3
            },
            {
              "name": "HONG HU SHI",
              "code": 4
            },
            {
              "name": "SONG ZI SHI",
              "code": 5
            },
            {
              "name": "GONG AN XIAN",
              "code": 6
            },
            {
              "name": "JIAN LI XIAN",
              "code": 7
            },
            {
              "name": "JIANG LING XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "QIAN JIANG",
          "code": 8,
          "city": [
            {
              "name": "QIAN JIANG SHI",
              "code": 1
            }
          ]
        },
        {
          "name": "SHEN NONG JIA LIN QU",
          "code": 9,
          "city": [
            {
              "name": "SHEN NONG JIA LIN QU",
              "code": 1
            }
          ]
        },
        {
          "name": "SHI YAN",
          "code": 10,
          "city": [
            {
              "name": "ZHANG WAN QU",
              "code": 1
            },
            {
              "name": "MAO JIAN QU",
              "code": 2
            },
            {
              "name": "DAN JIANG KOU SHI",
              "code": 3
            },
            {
              "name": "YUN XIAN",
              "code": 4
            },
            {
              "name": "YUN XI XIAN",
              "code": 5
            },
            {
              "name": "ZHU SHAN XIAN",
              "code": 6
            },
            {
              "name": "ZHU XI XIAN",
              "code": 7
            },
            {
              "name": "FANG XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "SUI ZHOU",
          "code": 11,
          "city": [
            {
              "name": "ZENG DU QU",
              "code": 1
            },
            {
              "name": "GUANG SHUI SHI",
              "code": 2
            }
          ]
        },
        {
          "name": "TIAN MEN",
          "code": 12,
          "city": [
            {
              "name": "TIAN MEN SHI",
              "code": 1
            }
          ]
        },
        {
          "name": "XIAN NING",
          "code": 13,
          "city": [
            {
              "name": "XIAN AN QU",
              "code": 1
            },
            {
              "name": "CHI BI SHI",
              "code": 2
            },
            {
              "name": "JIA YU XIAN",
              "code": 3
            },
            {
              "name": "TONG CHENG XIAN",
              "code": 4
            },
            {
              "name": "CHONG YANG XIAN",
              "code": 5
            },
            {
              "name": "TONG SHAN XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "XIANG FAN",
          "code": 14,
          "city": [
            {
              "name": "XIANG CHENG QU",
              "code": 1
            },
            {
              "name": "FAN CHENG QU",
              "code": 2
            },
            {
              "name": "XIANG YANG QU",
              "code": 3
            },
            {
              "name": "LAO HE KOU SHI",
              "code": 4
            },
            {
              "name": "ZAO YANG SHI",
              "code": 5
            },
            {
              "name": "YI CHENG SHI",
              "code": 6
            },
            {
              "name": "NAN ZHANG XIAN",
              "code": 7
            },
            {
              "name": "GU CHENG XIAN",
              "code": 8
            },
            {
              "name": "BAO KANG XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "XIAO GAN",
          "code": 15,
          "city": [
            {
              "name": "XIAO NAN QU",
              "code": 1
            },
            {
              "name": "YING CHENG SHI",
              "code": 2
            },
            {
              "name": "AN LU SHI",
              "code": 3
            },
            {
              "name": "HAN CHUAN SHI",
              "code": 4
            },
            {
              "name": "XIAO CHANG XIAN",
              "code": 5
            },
            {
              "name": "DA WU XIAN",
              "code": 6
            },
            {
              "name": "YUN MENG XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "YI CHANG",
          "code": 16,
          "city": [
            {
              "name": "CHANG YANG",
              "code": 1
            },
            {
              "name": "WU FENG",
              "code": 2
            },
            {
              "name": "XI LING QU",
              "code": 3
            },
            {
              "name": "WU JIA GANG QU",
              "code": 4
            },
            {
              "name": "DIAN JUN QU",
              "code": 5
            },
            {
              "name": "XIAO TING QU",
              "code": 6
            },
            {
              "name": "YI LING QU",
              "code": 7
            },
            {
              "name": "YI DU SHI",
              "code": 8
            },
            {
              "name": "DANG YANG SHI",
              "code": 9
            },
            {
              "name": "ZHI JIANG SHI",
              "code": 10
            },
            {
              "name": "YUAN AN XIAN",
              "code": 11
            },
            {
              "name": "XING SHAN XIAN",
              "code": 12
            },
            {
              "name": "ZI GUI XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "EN SHI",
          "code": 17,
          "city": [
            {
              "name": "EN SHI SHI",
              "code": 1
            },
            {
              "name": "LI CHUAN SHI",
              "code": 2
            },
            {
              "name": "JIAN SHI XIAN",
              "code": 3
            },
            {
              "name": "BA DONG XIAN",
              "code": 4
            },
            {
              "name": "XUAN EN XIAN",
              "code": 5
            },
            {
              "name": "XIAN FENG XIAN",
              "code": 6
            },
            {
              "name": "LAI FENG XIAN",
              "code": 7
            },
            {
              "name": "HE FENG XIAN",
              "code": 8
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "HU NAN",
      "code": 13,
      "state": [
        {
          "name": "CHANG SHA",
          "code": 1,
          "city": [
            {
              "name": "YUE LU QU",
              "code": 1
            },
            {
              "name": "FU RONG QU",
              "code": 2
            },
            {
              "name": "TIAN XIN QU",
              "code": 3
            },
            {
              "name": "KAI FU QU",
              "code": 4
            },
            {
              "name": "YU HUA QU",
              "code": 5
            },
            {
              "name": "KAI FA QU",
              "code": 6
            },
            {
              "name": "LIU YANG SHI",
              "code": 7
            },
            {
              "name": "CHANG SHA XIAN",
              "code": 8
            },
            {
              "name": "WANG CHENG XIAN",
              "code": 9
            },
            {
              "name": "NING XIANG XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "ZHANG JIA JIE",
          "code": 2,
          "city": [
            {
              "name": "YONG DING QU",
              "code": 1
            },
            {
              "name": "WU LING YUAN QU",
              "code": 2
            },
            {
              "name": "CI LI XIAN",
              "code": 3
            },
            {
              "name": "SANG ZHI XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "CHANG DE",
          "code": 3,
          "city": [
            {
              "name": "WU LING QU",
              "code": 1
            },
            {
              "name": "DING CHENG QU",
              "code": 2
            },
            {
              "name": "JIN SHI SHI",
              "code": 3
            },
            {
              "name": "AN XIANG XIAN",
              "code": 4
            },
            {
              "name": "HAN SHOU XIAN",
              "code": 5
            },
            {
              "name": "LI XIAN",
              "code": 6
            },
            {
              "name": "LIN LI XIAN",
              "code": 7
            },
            {
              "name": "TAO YUAN XIAN",
              "code": 8
            },
            {
              "name": "SHI MEN XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "CHEN ZHOU",
          "code": 4,
          "city": [
            {
              "name": "BEI HU QU",
              "code": 1
            },
            {
              "name": "SU XIAN QU",
              "code": 2
            },
            {
              "name": "ZI XING SHI",
              "code": 3
            },
            {
              "name": "GUI YANG XIAN",
              "code": 4
            },
            {
              "name": "YI ZHANG XIAN",
              "code": 5
            },
            {
              "name": "YONG XING XIAN",
              "code": 6
            },
            {
              "name": "JIA HE XIAN",
              "code": 7
            },
            {
              "name": "LIN WU XIAN",
              "code": 8
            },
            {
              "name": "RU CHENG XIAN",
              "code": 9
            },
            {
              "name": "GUI DONG XIAN",
              "code": 10
            },
            {
              "name": "AN REN XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "HENG YANG",
          "code": 5,
          "city": [
            {
              "name": "YAN FENG QU",
              "code": 1
            },
            {
              "name": "ZHU HUI QU",
              "code": 2
            },
            {
              "name": "DAN GU QU",
              "code": 3
            },
            {
              "name": "ZHENG XIANG QU",
              "code": 4
            },
            {
              "name": "NAN YUE QU",
              "code": 5
            },
            {
              "name": "LEI YANG SHI",
              "code": 6
            },
            {
              "name": "CHANG NING SHI",
              "code": 7
            },
            {
              "name": "HENG YANG XIAN",
              "code": 8
            },
            {
              "name": "HENG NAN XIAN",
              "code": 9
            },
            {
              "name": "HENG SHAN XIAN",
              "code": 10
            },
            {
              "name": "HENG DONG XIAN",
              "code": 11
            },
            {
              "name": "QI DONG XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "HUAI HUA",
          "code": 6,
          "city": [
            {
              "name": "HE CHENG QU",
              "code": 1
            },
            {
              "name": "JING ZHOU",
              "code": 2
            },
            {
              "name": "MA YANG",
              "code": 3
            },
            {
              "name": "TONG DAO",
              "code": 4
            },
            {
              "name": "XIN HUANG",
              "code": 5
            },
            {
              "name": "ZHI JIANG",
              "code": 6
            },
            {
              "name": "YUAN LING XIAN",
              "code": 7
            },
            {
              "name": "CHEN XI XIAN",
              "code": 8
            },
            {
              "name": "XU PU XIAN",
              "code": 9
            },
            {
              "name": "ZHONG FANG XIAN",
              "code": 10
            },
            {
              "name": "HUI TONG XIAN",
              "code": 11
            },
            {
              "name": "HONG JIANG SHI",
              "code": 12
            }
          ]
        },
        {
          "name": "LOU DI",
          "code": 7,
          "city": [
            {
              "name": "LOU XING QU",
              "code": 1
            },
            {
              "name": "LENG SHUI JIANG SHI",
              "code": 2
            },
            {
              "name": "LIAN YUAN SHI",
              "code": 3
            },
            {
              "name": "SHUANG FENG XIAN",
              "code": 4
            },
            {
              "name": "XIN HUA XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "SHAO YANG",
          "code": 8,
          "city": [
            {
              "name": "CHENG BU",
              "code": 1
            },
            {
              "name": "SHUANG QING QU",
              "code": 2
            },
            {
              "name": "DA XIANG QU",
              "code": 3
            },
            {
              "name": "BEI TA QU",
              "code": 4
            },
            {
              "name": "WU GANG SHI",
              "code": 5
            },
            {
              "name": "SHAO DONG XIAN",
              "code": 6
            },
            {
              "name": "XIN SHAO XIAN",
              "code": 7
            },
            {
              "name": "SHAO YANG XIAN",
              "code": 8
            },
            {
              "name": "LONG HUI XIAN",
              "code": 9
            },
            {
              "name": "DONG KOU XIAN",
              "code": 10
            },
            {
              "name": "SUI NING XIAN",
              "code": 11
            },
            {
              "name": "XIN NING XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "XIANG TAN",
          "code": 9,
          "city": [
            {
              "name": "YUE TANG QU",
              "code": 1
            },
            {
              "name": "YU HU QU",
              "code": 2
            },
            {
              "name": "XIANG XIANG SHI",
              "code": 3
            },
            {
              "name": "SHAO SHAN SHI",
              "code": 4
            },
            {
              "name": "XIANG TAN XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "XIANG XI",
          "code": 10,
          "city": [
            {
              "name": "JI SHOU SHI",
              "code": 1
            },
            {
              "name": "LU XI XIAN",
              "code": 2
            },
            {
              "name": "FENG HUANG XIAN",
              "code": 3
            },
            {
              "name": "HUA YUAN XIAN",
              "code": 4
            },
            {
              "name": "BAO JING XIAN",
              "code": 5
            },
            {
              "name": "GU ZHANG XIAN",
              "code": 6
            },
            {
              "name": "YONG SHUN XIAN",
              "code": 7
            },
            {
              "name": "LONG SHAN XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "YI YANG",
          "code": 11,
          "city": [
            {
              "name": "HE SHAN QU",
              "code": 1
            },
            {
              "name": "ZI YANG QU",
              "code": 2
            },
            {
              "name": "YUAN JIANG SHI",
              "code": 3
            },
            {
              "name": "NAN XIAN",
              "code": 4
            },
            {
              "name": "TAO JIANG XIAN",
              "code": 5
            },
            {
              "name": "AN HUA XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "YONG ZHOU",
          "code": 12,
          "city": [
            {
              "name": "JIANG HUA",
              "code": 1
            },
            {
              "name": "LENG SHUI TAN QU",
              "code": 2
            },
            {
              "name": "LING LING QU",
              "code": 3
            },
            {
              "name": "QI YANG XIAN",
              "code": 4
            },
            {
              "name": "DONG AN XIAN",
              "code": 5
            },
            {
              "name": "SHUANG PAI XIAN",
              "code": 6
            },
            {
              "name": "DAO XIAN",
              "code": 7
            },
            {
              "name": "JIANG YONG XIAN",
              "code": 8
            },
            {
              "name": "NING YUAN XIAN",
              "code": 9
            },
            {
              "name": "LAN SHAN XIAN",
              "code": 10
            },
            {
              "name": "XIN TIAN XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "YUE YANG",
          "code": 13,
          "city": [
            {
              "name": "YUE YANG LOU QU",
              "code": 1
            },
            {
              "name": "JUN SHAN QU",
              "code": 2
            },
            {
              "name": "YUN XI QU",
              "code": 3
            },
            {
              "name": "MI LUO SHI",
              "code": 4
            },
            {
              "name": "LIN XIANG SHI",
              "code": 5
            },
            {
              "name": "YUE YANG XIAN",
              "code": 6
            },
            {
              "name": "HUA RONG XIAN",
              "code": 7
            },
            {
              "name": "XIANG YIN XIAN",
              "code": 8
            },
            {
              "name": "PING JIANG XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "ZHU ZHOU",
          "code": 14,
          "city": [
            {
              "name": "TIAN YUAN QU",
              "code": 1
            },
            {
              "name": "HE TANG QU",
              "code": 2
            },
            {
              "name": "LU SONG QU",
              "code": 3
            },
            {
              "name": "SHI FENG QU",
              "code": 4
            },
            {
              "name": "LI LING SHI",
              "code": 5
            },
            {
              "name": "ZHU ZHOU XIAN",
              "code": 6
            },
            {
              "name": "YOU XIAN",
              "code": 7
            },
            {
              "name": "CHA LING XIAN",
              "code": 8
            },
            {
              "name": "YAN LING XIAN",
              "code": 9
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "JI LIN",
      "code": 14,
      "state": [
        {
          "name": "CHANG CHUN",
          "code": 1,
          "city": [
            {
              "name": "CHAO YANG QU",
              "code": 1
            },
            {
              "name": "KUAN CHENG QU",
              "code": 2
            },
            {
              "name": "ER DAO QU",
              "code": 3
            },
            {
              "name": "NAN GUAN QU",
              "code": 4
            },
            {
              "name": "LYU YUAN QU",
              "code": 5
            },
            {
              "name": "SHUANG YANG QU",
              "code": 6
            },
            {
              "name": "JING YUE TAN KAI FA QU",
              "code": 7
            },
            {
              "name": "GAO XIN JI SHU KAI FA QU",
              "code": 8
            },
            {
              "name": "JING JI JI SHU KAI FA QU",
              "code": 9
            },
            {
              "name": "QI CHE CHAN YE KAI FA QU",
              "code": 10
            },
            {
              "name": "DE HUI SHI",
              "code": 11
            },
            {
              "name": "JIU TAI SHI",
              "code": 12
            },
            {
              "name": "YU SHU SHI",
              "code": 13
            },
            {
              "name": "NONG AN XIAN",
              "code": 14
            }
          ]
        },
        {
          "name": "JI LIN",
          "code": 2,
          "city": [
            {
              "name": "CHUAN YING QU",
              "code": 1
            },
            {
              "name": "CHANG YI QU",
              "code": 2
            },
            {
              "name": "LONG TAN QU",
              "code": 3
            },
            {
              "name": "FENG MAN QU",
              "code": 4
            },
            {
              "name": "JIAO HE SHI",
              "code": 5
            },
            {
              "name": "HUA DIAN SHI",
              "code": 6
            },
            {
              "name": "SHU LAN SHI",
              "code": 7
            },
            {
              "name": "PAN SHI SHI",
              "code": 8
            },
            {
              "name": "YONG JI XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "BAI CHENG",
          "code": 3,
          "city": [
            {
              "name": "TAO BEI QU",
              "code": 1
            },
            {
              "name": "TAO NAN SHI",
              "code": 2
            },
            {
              "name": "DA AN SHI",
              "code": 3
            },
            {
              "name": "ZHEN LAI XIAN",
              "code": 4
            },
            {
              "name": "TONG YU XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "BAI SHAN",
          "code": 4,
          "city": [
            {
              "name": "JIANG YUAN QU",
              "code": 1
            },
            {
              "name": "BA DAO JIANG QU",
              "code": 2
            },
            {
              "name": "CHANG BAI",
              "code": 3
            },
            {
              "name": "LIN JIANG SHI",
              "code": 4
            },
            {
              "name": "FU SONG XIAN",
              "code": 5
            },
            {
              "name": "JING YU XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "LIAO YUAN",
          "code": 5,
          "city": [
            {
              "name": "LONG SHAN QU",
              "code": 1
            },
            {
              "name": "XI AN QU",
              "code": 2
            },
            {
              "name": "DONG FENG XIAN",
              "code": 3
            },
            {
              "name": "DONG LIAO XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "SI PING",
          "code": 6,
          "city": [
            {
              "name": "TIE XI QU",
              "code": 1
            },
            {
              "name": "TIE DONG QU",
              "code": 2
            },
            {
              "name": "YI TONG",
              "code": 3
            },
            {
              "name": "GONG ZHU LING SHI",
              "code": 4
            },
            {
              "name": "SHUANG LIAO SHI",
              "code": 5
            },
            {
              "name": "LI SHU XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "SONG YUAN",
          "code": 7,
          "city": [
            {
              "name": "QIAN GUO ER LUO SI",
              "code": 1
            },
            {
              "name": "NING JIANG QU",
              "code": 2
            },
            {
              "name": "CHANG LING XIAN",
              "code": 3
            },
            {
              "name": "QIAN AN XIAN",
              "code": 4
            },
            {
              "name": "FU YU XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "TONG HUA",
          "code": 8,
          "city": [
            {
              "name": "DONG CHANG QU",
              "code": 1
            },
            {
              "name": "ER DAO JIANG QU",
              "code": 2
            },
            {
              "name": "MEI HE KOU SHI",
              "code": 3
            },
            {
              "name": "JI AN SHI",
              "code": 4
            },
            {
              "name": "TONG HUA XIAN",
              "code": 5
            },
            {
              "name": "HUI NAN XIAN",
              "code": 6
            },
            {
              "name": "LIU HE XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "YAN BIAN",
          "code": 9,
          "city": [
            {
              "name": "YAN JI SHI",
              "code": 1
            },
            {
              "name": "TU MEN SHI",
              "code": 2
            },
            {
              "name": "DUN HUA SHI",
              "code": 3
            },
            {
              "name": "HUN CHUN SHI",
              "code": 4
            },
            {
              "name": "LONG JING SHI",
              "code": 5
            },
            {
              "name": "HE LONG SHI",
              "code": 6
            },
            {
              "name": "AN TU XIAN",
              "code": 7
            },
            {
              "name": "WANG QING XIAN",
              "code": 8
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "JIANG SU",
      "code": 15,
      "state": [
        {
          "name": "NAN JING",
          "code": 1,
          "city": [
            {
              "name": "XUAN WU QU",
              "code": 1
            },
            {
              "name": "GU LOU QU",
              "code": 2
            },
            {
              "name": "BAI XIA QU",
              "code": 3
            },
            {
              "name": "JIAN YE QU",
              "code": 4
            },
            {
              "name": "QIN HUAI QU",
              "code": 5
            },
            {
              "name": "YU HUA TAI QU",
              "code": 6
            },
            {
              "name": "XIA GUAN QU",
              "code": 7
            },
            {
              "name": "QI XIA QU",
              "code": 8
            },
            {
              "name": "PU KOU QU",
              "code": 9
            },
            {
              "name": "JIANG NING QU",
              "code": 10
            },
            {
              "name": "LU HE QU",
              "code": 11
            },
            {
              "name": "LI SHUI XIAN",
              "code": 12
            },
            {
              "name": "GAO CHUN XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "SU ZHOU",
          "code": 2,
          "city": [
            {
              "name": "CANG LANG QU",
              "code": 1
            },
            {
              "name": "JIN CHANG QU",
              "code": 2
            },
            {
              "name": "PING JIANG QU",
              "code": 3
            },
            {
              "name": "HU QIU QU",
              "code": 4
            },
            {
              "name": "WU ZHONG QU",
              "code": 5
            },
            {
              "name": "XIANG CHENG QU",
              "code": 6
            },
            {
              "name": "YUAN QU",
              "code": 7
            },
            {
              "name": "XIN QU",
              "code": 8
            },
            {
              "name": "CHANG SHU SHI",
              "code": 9
            },
            {
              "name": "ZHANG JIA GANG SHI",
              "code": 10
            },
            {
              "name": "YU SHAN ZHEN",
              "code": 11
            },
            {
              "name": "BA CHENG ZHEN",
              "code": 12
            },
            {
              "name": "ZHOU SHI ZHEN",
              "code": 13
            },
            {
              "name": "LU JIA ZHEN",
              "code": 14
            },
            {
              "name": "HUA QIAO ZHEN",
              "code": 15
            },
            {
              "name": "DIAN SHAN HU ZHEN",
              "code": 16
            },
            {
              "name": "ZHANG PU ZHEN",
              "code": 17
            },
            {
              "name": "ZHOU ZHUANG ZHEN",
              "code": 18
            },
            {
              "name": "QIAN DENG ZHEN",
              "code": 19
            },
            {
              "name": "JIN XI ZHEN",
              "code": 20
            },
            {
              "name": "KAI FA QU",
              "code": 21
            },
            {
              "name": "WU JIANG SHI",
              "code": 22
            },
            {
              "name": "TAI CANG SHI",
              "code": 23
            }
          ]
        },
        {
          "name": "WU XI",
          "code": 3,
          "city": [
            {
              "name": "CHONG AN QU",
              "code": 1
            },
            {
              "name": "BEI TANG QU",
              "code": 2
            },
            {
              "name": "NAN CHANG QU",
              "code": 3
            },
            {
              "name": "XI SHAN QU",
              "code": 4
            },
            {
              "name": "HUI SHAN QU",
              "code": 5
            },
            {
              "name": "BIN HU QU",
              "code": 6
            },
            {
              "name": "XIN QU",
              "code": 7
            },
            {
              "name": "JIANG YIN SHI",
              "code": 8
            },
            {
              "name": "YI XING SHI",
              "code": 9
            }
          ]
        },
        {
          "name": "CHANG ZHOU",
          "code": 4,
          "city": [
            {
              "name": "TIAN NING QU",
              "code": 1
            },
            {
              "name": "ZHONG LOU QU",
              "code": 2
            },
            {
              "name": "QI SHU YAN QU",
              "code": 3
            },
            {
              "name": "JIAO QU",
              "code": 4
            },
            {
              "name": "XIN BEI QU",
              "code": 5
            },
            {
              "name": "WU JIN QU",
              "code": 6
            },
            {
              "name": "LI YANG SHI",
              "code": 7
            },
            {
              "name": "JIN TAN SHI",
              "code": 8
            }
          ]
        },
        {
          "name": "HUAI AN",
          "code": 5,
          "city": [
            {
              "name": "QING HE QU",
              "code": 1
            },
            {
              "name": "QING PU QU",
              "code": 2
            },
            {
              "name": "CHU ZHOU QU",
              "code": 3
            },
            {
              "name": "HUAI YIN QU",
              "code": 4
            },
            {
              "name": "LIAN SHUI XIAN",
              "code": 5
            },
            {
              "name": "HONG ZE XIAN",
              "code": 6
            },
            {
              "name": "XU YI XIAN",
              "code": 7
            },
            {
              "name": "JIN HU XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "LIAN YUN GANG",
          "code": 6,
          "city": [
            {
              "name": "XIN PU QU",
              "code": 1
            },
            {
              "name": "LIAN YUN QU",
              "code": 2
            },
            {
              "name": "HAI ZHOU QU",
              "code": 3
            },
            {
              "name": "GAN YU XIAN",
              "code": 4
            },
            {
              "name": "DONG HAI XIAN",
              "code": 5
            },
            {
              "name": "GUAN YUN XIAN",
              "code": 6
            },
            {
              "name": "GUAN NAN XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "NAN TONG",
          "code": 7,
          "city": [
            {
              "name": "CHONG CHUAN QU",
              "code": 1
            },
            {
              "name": "GANG ZHA QU",
              "code": 2
            },
            {
              "name": "JING JI KAI FA QU",
              "code": 3
            },
            {
              "name": "QI DONG SHI",
              "code": 4
            },
            {
              "name": "RU GAO SHI",
              "code": 5
            },
            {
              "name": "TONG ZHOU SHI",
              "code": 6
            },
            {
              "name": "HAI MEN SHI",
              "code": 7
            },
            {
              "name": "HAI AN XIAN",
              "code": 8
            },
            {
              "name": "RU DONG XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "SU QIAN",
          "code": 8,
          "city": [
            {
              "name": "SU CHENG QU",
              "code": 1
            },
            {
              "name": "SU YU QU",
              "code": 2
            },
            {
              "name": "SU YU XIAN",
              "code": 3
            },
            {
              "name": "SHU YANG XIAN",
              "code": 4
            },
            {
              "name": "SI YANG XIAN",
              "code": 5
            },
            {
              "name": "SI HONG XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "TAI ZHOU",
          "code": 9,
          "city": [
            {
              "name": "HAI LING QU",
              "code": 1
            },
            {
              "name": "GAO GANG QU",
              "code": 2
            },
            {
              "name": "XING HUA SHI",
              "code": 3
            },
            {
              "name": "JING JIANG SHI",
              "code": 4
            },
            {
              "name": "TAI XING SHI",
              "code": 5
            },
            {
              "name": "JIANG YAN SHI",
              "code": 6
            }
          ]
        },
        {
          "name": "XU ZHOU",
          "code": 10,
          "city": [
            {
              "name": "YUN LONG QU",
              "code": 1
            },
            {
              "name": "GU LOU QU",
              "code": 2
            },
            {
              "name": "JIU LI QU",
              "code": 3
            },
            {
              "name": "JIA WANG QU",
              "code": 4
            },
            {
              "name": "QUAN SHAN QU",
              "code": 5
            },
            {
              "name": "XIN YI SHI",
              "code": 6
            },
            {
              "name": "PI ZHOU SHI",
              "code": 7
            },
            {
              "name": "FENG XIAN",
              "code": 8
            },
            {
              "name": "PEI XIAN",
              "code": 9
            },
            {
              "name": "TONG SHAN XIAN",
              "code": 10
            },
            {
              "name": "SUI NING XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "YAN CHENG",
          "code": 11,
          "city": [
            {
              "name": "CHENG QU",
              "code": 1
            },
            {
              "name": "TING HU QU",
              "code": 2
            },
            {
              "name": "YAN DU QU",
              "code": 3
            },
            {
              "name": "YAN DU XIAN",
              "code": 4
            },
            {
              "name": "DONG TAI SHI",
              "code": 5
            },
            {
              "name": "DA FENG SHI",
              "code": 6
            },
            {
              "name": "XIANG SHUI XIAN",
              "code": 7
            },
            {
              "name": "BIN HAI XIAN",
              "code": 8
            },
            {
              "name": "FU NING XIAN",
              "code": 9
            },
            {
              "name": "SHE YANG XIAN",
              "code": 10
            },
            {
              "name": "JIAN HU XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "YANG ZHOU",
          "code": 12,
          "city": [
            {
              "name": "GUANG LING QU",
              "code": 1
            },
            {
              "name": "WEI YANG QU",
              "code": 2
            },
            {
              "name": "HAN JIANG QU",
              "code": 3
            },
            {
              "name": "YI ZHENG SHI",
              "code": 4
            },
            {
              "name": "GAO YOU SHI",
              "code": 5
            },
            {
              "name": "JIANG DU SHI",
              "code": 6
            },
            {
              "name": "BAO YING XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "ZHEN JIANG",
          "code": 13,
          "city": [
            {
              "name": "JING KOU QU",
              "code": 1
            },
            {
              "name": "RUN ZHOU QU",
              "code": 2
            },
            {
              "name": "DAN TU QU",
              "code": 3
            },
            {
              "name": "DAN YANG SHI",
              "code": 4
            },
            {
              "name": "YANG ZHONG SHI",
              "code": 5
            },
            {
              "name": "JU RONG SHI",
              "code": 6
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "JIANG XI",
      "code": 16,
      "state": [
        {
          "name": "NAN CHANG",
          "code": 1,
          "city": [
            {
              "name": "DONG HU QU",
              "code": 1
            },
            {
              "name": "XI HU QU",
              "code": 2
            },
            {
              "name": "QING YUN PU QU",
              "code": 3
            },
            {
              "name": "WAN LI QU",
              "code": 4
            },
            {
              "name": "QING SHAN HU QU",
              "code": 5
            },
            {
              "name": "HONG GU TAN XIN QU",
              "code": 6
            },
            {
              "name": "CHANG BEI QU",
              "code": 7
            },
            {
              "name": "GAO XIN QU",
              "code": 8
            },
            {
              "name": "NAN CHANG XIAN",
              "code": 9
            },
            {
              "name": "XIN JIAN XIAN",
              "code": 10
            },
            {
              "name": "AN YI XIAN",
              "code": 11
            },
            {
              "name": "JIN XIAN XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "FU ZHOU",
          "code": 2,
          "city": [
            {
              "name": "LIN CHUAN QU",
              "code": 1
            },
            {
              "name": "NAN CHENG XIAN",
              "code": 2
            },
            {
              "name": "LI CHUAN XIAN",
              "code": 3
            },
            {
              "name": "NAN FENG XIAN",
              "code": 4
            },
            {
              "name": "CHONG REN XIAN",
              "code": 5
            },
            {
              "name": "LE AN XIAN",
              "code": 6
            },
            {
              "name": "YI HUANG XIAN",
              "code": 7
            },
            {
              "name": "JIN XI XIAN",
              "code": 8
            },
            {
              "name": "ZI XI XIAN",
              "code": 9
            },
            {
              "name": "DONG XIANG XIAN",
              "code": 10
            },
            {
              "name": "GUANG CHANG XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "GAN ZHOU",
          "code": 3,
          "city": [
            {
              "name": "ZHANG GONG QU",
              "code": 1
            },
            {
              "name": "YU DU XIAN",
              "code": 2
            },
            {
              "name": "RUI JIN SHI",
              "code": 3
            },
            {
              "name": "NAN KANG SHI",
              "code": 4
            },
            {
              "name": "GAN XIAN",
              "code": 5
            },
            {
              "name": "XIN FENG XIAN",
              "code": 6
            },
            {
              "name": "DA YU XIAN",
              "code": 7
            },
            {
              "name": "SHANG YOU XIAN",
              "code": 8
            },
            {
              "name": "CHONG YI XIAN",
              "code": 9
            },
            {
              "name": "AN YUAN XIAN",
              "code": 10
            },
            {
              "name": "LONG NAN XIAN",
              "code": 11
            },
            {
              "name": "DING NAN XIAN",
              "code": 12
            },
            {
              "name": "QUAN NAN XIAN",
              "code": 13
            },
            {
              "name": "NING DU XIAN",
              "code": 14
            },
            {
              "name": "XING GUO XIAN",
              "code": 15
            },
            {
              "name": "HUI CHANG XIAN",
              "code": 16
            },
            {
              "name": "XUN WU XIAN",
              "code": 17
            },
            {
              "name": "SHI CHENG XIAN",
              "code": 18
            }
          ]
        },
        {
          "name": "JI AN",
          "code": 4,
          "city": [
            {
              "name": "AN FU XIAN",
              "code": 1
            },
            {
              "name": "JI ZHOU QU",
              "code": 2
            },
            {
              "name": "QING YUAN QU",
              "code": 3
            },
            {
              "name": "JING GANG SHAN SHI",
              "code": 4
            },
            {
              "name": "JI AN XIAN",
              "code": 5
            },
            {
              "name": "JI SHUI XIAN",
              "code": 6
            },
            {
              "name": "XIA JIANG XIAN",
              "code": 7
            },
            {
              "name": "XIN GAN XIAN",
              "code": 8
            },
            {
              "name": "YONG FENG XIAN",
              "code": 9
            },
            {
              "name": "TAI HE XIAN",
              "code": 10
            },
            {
              "name": "SUI CHUAN XIAN",
              "code": 11
            },
            {
              "name": "WAN AN XIAN",
              "code": 12
            },
            {
              "name": "YONG XIN XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "JING DE ZHEN",
          "code": 5,
          "city": [
            {
              "name": "ZHU SHAN QU",
              "code": 1
            },
            {
              "name": "CHANG JIANG QU",
              "code": 2
            },
            {
              "name": "LE PING SHI",
              "code": 3
            },
            {
              "name": "FU LIANG XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "JIU JIANG",
          "code": 6,
          "city": [
            {
              "name": "XUN YANG QU",
              "code": 1
            },
            {
              "name": "LU SHAN QU",
              "code": 2
            },
            {
              "name": "RUI CHANG SHI",
              "code": 3
            },
            {
              "name": "JIU JIANG XIAN",
              "code": 4
            },
            {
              "name": "WU NING XIAN",
              "code": 5
            },
            {
              "name": "XIU SHUI XIAN",
              "code": 6
            },
            {
              "name": "YONG XIU XIAN",
              "code": 7
            },
            {
              "name": "DE AN XIAN",
              "code": 8
            },
            {
              "name": "XING ZI XIAN",
              "code": 9
            },
            {
              "name": "DU CHANG XIAN",
              "code": 10
            },
            {
              "name": "HU KOU XIAN",
              "code": 11
            },
            {
              "name": "PENG ZE XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "PING XIANG",
          "code": 7,
          "city": [
            {
              "name": "AN YUAN QU",
              "code": 1
            },
            {
              "name": "XIANG DONG QU",
              "code": 2
            },
            {
              "name": "LIAN HUA XIAN",
              "code": 3
            },
            {
              "name": "LU XI XIAN",
              "code": 4
            },
            {
              "name": "SHANG LI XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "SHANG RAO",
          "code": 8,
          "city": [
            {
              "name": "XIN ZHOU QU",
              "code": 1
            },
            {
              "name": "DE XING SHI",
              "code": 2
            },
            {
              "name": "SHANG RAO XIAN",
              "code": 3
            },
            {
              "name": "GUANG FENG XIAN",
              "code": 4
            },
            {
              "name": "YU SHAN XIAN",
              "code": 5
            },
            {
              "name": "YAN SHAN XIAN",
              "code": 6
            },
            {
              "name": "HENG FENG XIAN",
              "code": 7
            },
            {
              "name": "YI YANG XIAN",
              "code": 8
            },
            {
              "name": "YU GAN XIAN",
              "code": 9
            },
            {
              "name": "BO YANG XIAN",
              "code": 10
            },
            {
              "name": "WAN NIAN XIAN",
              "code": 11
            },
            {
              "name": "WU YUAN XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "XIN YU",
          "code": 9,
          "city": [
            {
              "name": "YU SHUI QU",
              "code": 1
            },
            {
              "name": "FEN YI XIAN",
              "code": 2
            }
          ]
        },
        {
          "name": "YI CHUN",
          "code": 10,
          "city": [
            {
              "name": "YUAN ZHOU QU",
              "code": 1
            },
            {
              "name": "FENG CHENG SHI",
              "code": 2
            },
            {
              "name": "ZHANG SHU SHI",
              "code": 3
            },
            {
              "name": "GAO AN SHI",
              "code": 4
            },
            {
              "name": "FENG XIN XIAN",
              "code": 5
            },
            {
              "name": "WAN ZAI XIAN",
              "code": 6
            },
            {
              "name": "SHANG GAO XIAN",
              "code": 7
            },
            {
              "name": "YI FENG XIAN",
              "code": 8
            },
            {
              "name": "JING AN XIAN",
              "code": 9
            },
            {
              "name": "TONG GU XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "YING TAN",
          "code": 11,
          "city": [
            {
              "name": "YUE HU QU",
              "code": 1
            },
            {
              "name": "GUI XI SHI",
              "code": 2
            },
            {
              "name": "YU JIANG XIAN",
              "code": 3
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "LIAO NING",
      "code": 17,
      "state": [
        {
          "name": "SHEN YANG",
          "code": 1,
          "city": [
            {
              "name": "SHEN HE QU",
              "code": 1
            },
            {
              "name": "HUANG GU QU",
              "code": 2
            },
            {
              "name": "HE PING QU",
              "code": 3
            },
            {
              "name": "DA DONG QU",
              "code": 4
            },
            {
              "name": "TIE XI QU",
              "code": 5
            },
            {
              "name": "SU JIA TUN QU",
              "code": 6
            },
            {
              "name": "DONG LING QU",
              "code": 7
            },
            {
              "name": "SHEN BEI XIN QU",
              "code": 8
            },
            {
              "name": "YU HONG QU",
              "code": 9
            },
            {
              "name": "HUN NAN XIN QU",
              "code": 10
            },
            {
              "name": "XIN MIN SHI",
              "code": 11
            },
            {
              "name": "LIAO ZHONG XIAN",
              "code": 12
            },
            {
              "name": "KANG PING XIAN",
              "code": 13
            },
            {
              "name": "FA KU XIAN",
              "code": 14
            }
          ]
        },
        {
          "name": "DA LIAN",
          "code": 2,
          "city": [
            {
              "name": "XI GANG QU",
              "code": 1
            },
            {
              "name": "ZHONG SHAN QU",
              "code": 2
            },
            {
              "name": "SHA HE KOU QU",
              "code": 3
            },
            {
              "name": "GAN JING ZI QU",
              "code": 4
            },
            {
              "name": "LYU SHUN KOU QU",
              "code": 5
            },
            {
              "name": "JIN ZHOU QU",
              "code": 6
            },
            {
              "name": "KAI FA QU",
              "code": 7
            },
            {
              "name": "WA FANG DIAN SHI",
              "code": 8
            },
            {
              "name": "PU LAN DIAN SHI",
              "code": 9
            },
            {
              "name": "ZHUANG HE SHI",
              "code": 10
            },
            {
              "name": "CHANG HAI XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "AN SHAN",
          "code": 3,
          "city": [
            {
              "name": "TIE DONG QU",
              "code": 1
            },
            {
              "name": "TIE XI QU",
              "code": 2
            },
            {
              "name": "LI SHAN QU",
              "code": 3
            },
            {
              "name": "QIAN SHAN QU",
              "code": 4
            },
            {
              "name": "XIU YAN",
              "code": 5
            },
            {
              "name": "HAI CHENG SHI",
              "code": 6
            },
            {
              "name": "TAI AN XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "BEN XI",
          "code": 4,
          "city": [
            {
              "name": "BEN XI",
              "code": 1
            },
            {
              "name": "PING SHAN QU",
              "code": 2
            },
            {
              "name": "MING SHAN QU",
              "code": 3
            },
            {
              "name": "XI HU QU",
              "code": 4
            },
            {
              "name": "NAN FEN QU",
              "code": 5
            },
            {
              "name": "HUAN REN",
              "code": 6
            }
          ]
        },
        {
          "name": "ZHAO YANG",
          "code": 5,
          "city": [
            {
              "name": "SHUANG TA QU",
              "code": 1
            },
            {
              "name": "LONG CHENG QU",
              "code": 2
            },
            {
              "name": "KA LA QIN ZUO YI MENG GU ZU ZI ZHI XIAN",
              "code": 3
            },
            {
              "name": "BEI PIAO SHI",
              "code": 4
            },
            {
              "name": "LING YUAN SHI",
              "code": 5
            },
            {
              "name": "ZHAO YANG XIAN",
              "code": 6
            },
            {
              "name": "JIAN PING XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "DAN DONG",
          "code": 6,
          "city": [
            {
              "name": "ZHEN XING QU",
              "code": 1
            },
            {
              "name": "YUAN BAO QU",
              "code": 2
            },
            {
              "name": "ZHEN AN QU",
              "code": 3
            },
            {
              "name": "KUAN DIAN",
              "code": 4
            },
            {
              "name": "DONG GANG SHI",
              "code": 5
            },
            {
              "name": "FENG CHENG SHI",
              "code": 6
            }
          ]
        },
        {
          "name": "FU SHUN",
          "code": 7,
          "city": [
            {
              "name": "SHUN CHENG QU",
              "code": 1
            },
            {
              "name": "XIN FU QU",
              "code": 2
            },
            {
              "name": "DONG ZHOU QU",
              "code": 3
            },
            {
              "name": "WANG HUA QU",
              "code": 4
            },
            {
              "name": "QING YUAN",
              "code": 5
            },
            {
              "name": "XIN BIN",
              "code": 6
            },
            {
              "name": "FU SHUN XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "FU XIN",
          "code": 8,
          "city": [
            {
              "name": "FU XIN",
              "code": 1
            },
            {
              "name": "HAI ZHOU QU",
              "code": 2
            },
            {
              "name": "XIN QIU QU",
              "code": 3
            },
            {
              "name": "TAI PING QU",
              "code": 4
            },
            {
              "name": "QING HE MEN QU",
              "code": 5
            },
            {
              "name": "XI HE QU",
              "code": 6
            },
            {
              "name": "ZHANG WU XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "HU LU DAO",
          "code": 9,
          "city": [
            {
              "name": "LONG GANG QU",
              "code": 1
            },
            {
              "name": "NAN PIAO QU",
              "code": 2
            },
            {
              "name": "LIAN SHAN QU",
              "code": 3
            },
            {
              "name": "XING CHENG SHI",
              "code": 4
            },
            {
              "name": "SUI ZHONG XIAN",
              "code": 5
            },
            {
              "name": "JIAN CHANG XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "JIN ZHOU",
          "code": 10,
          "city": [
            {
              "name": "TAI HE QU",
              "code": 1
            },
            {
              "name": "GU TA QU",
              "code": 2
            },
            {
              "name": "LING HE QU",
              "code": 3
            },
            {
              "name": "LING HAI SHI",
              "code": 4
            },
            {
              "name": "BEI ZHEN SHI",
              "code": 5
            },
            {
              "name": "HEI SHAN XIAN",
              "code": 6
            },
            {
              "name": "YI XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "LIAO YANG",
          "code": 11,
          "city": [
            {
              "name": "BAI TA QU",
              "code": 1
            },
            {
              "name": "WEN SHENG QU",
              "code": 2
            },
            {
              "name": "HONG WEI QU",
              "code": 3
            },
            {
              "name": "TAI ZI HE QU",
              "code": 4
            },
            {
              "name": "GONG CHANG LING QU",
              "code": 5
            },
            {
              "name": "DENG TA SHI",
              "code": 6
            },
            {
              "name": "LIAO YANG XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "PAN JIN",
          "code": 12,
          "city": [
            {
              "name": "SHUANG TAI ZI QU",
              "code": 1
            },
            {
              "name": "XING LONG TAI QU",
              "code": 2
            },
            {
              "name": "DA WA XIAN",
              "code": 3
            },
            {
              "name": "PAN SHAN XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "TIE LING",
          "code": 13,
          "city": [
            {
              "name": "YIN ZHOU QU",
              "code": 1
            },
            {
              "name": "QING HE QU",
              "code": 2
            },
            {
              "name": "DIAO BING SHAN SHI",
              "code": 3
            },
            {
              "name": "KAI YUAN SHI",
              "code": 4
            },
            {
              "name": "TIE LING XIAN",
              "code": 5
            },
            {
              "name": "XI FENG XIAN",
              "code": 6
            },
            {
              "name": "CHANG TU XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "YING KOU",
          "code": 14,
          "city": [
            {
              "name": "ZHAN QIAN QU",
              "code": 1
            },
            {
              "name": "XI SHI QU",
              "code": 2
            },
            {
              "name": "BA YU QUAN QU",
              "code": 3
            },
            {
              "name": "LAO BIAN QU",
              "code": 4
            },
            {
              "name": "GAI ZHOU SHI",
              "code": 5
            },
            {
              "name": "DA SHI QIAO SHI",
              "code": 6
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "NEI MENG GU",
      "code": 18,
      "state": [
        {
          "name": "HU HE HAO TE",
          "code": 1,
          "city": [
            {
              "name": "HUI MIN QU",
              "code": 1
            },
            {
              "name": "YU QUAN QU",
              "code": 2
            },
            {
              "name": "XIN CHENG QU",
              "code": 3
            },
            {
              "name": "SAI HAN QU",
              "code": 4
            },
            {
              "name": "QING SHUI HE XIAN",
              "code": 5
            },
            {
              "name": "TU MO TE ZUO QI",
              "code": 6
            },
            {
              "name": "TUO KE TUO XIAN",
              "code": 7
            },
            {
              "name": "HE LIN GE ER XIAN",
              "code": 8
            },
            {
              "name": "WU CHUAN XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "A LA SHAN MENG",
          "code": 2,
          "city": [
            {
              "name": "A LA SHAN ZUO QI",
              "code": 1
            },
            {
              "name": "A LA SHAN YOU QI",
              "code": 2
            },
            {
              "name": "E JI NA QI",
              "code": 3
            }
          ]
        },
        {
          "name": "BA YAN NAO ER MENG",
          "code": 3,
          "city": [
            {
              "name": "LIN HE QU",
              "code": 1
            },
            {
              "name": "WU YUAN XIAN",
              "code": 2
            },
            {
              "name": "DENG KOU XIAN",
              "code": 3
            },
            {
              "name": "WU LA TE QIAN QI",
              "code": 4
            },
            {
              "name": "WU LA TE ZHONG QI",
              "code": 5
            },
            {
              "name": "WU LA TE HOU QI",
              "code": 6
            },
            {
              "name": "HANG JIN HOU QI",
              "code": 7
            }
          ]
        },
        {
          "name": "BAO TOU",
          "code": 4,
          "city": [
            {
              "name": "KUN DU LUN QU",
              "code": 1
            },
            {
              "name": "QING SHAN QU",
              "code": 2
            },
            {
              "name": "DONG HE QU",
              "code": 3
            },
            {
              "name": "JIU YUAN QU",
              "code": 4
            },
            {
              "name": "SHI GUAI QU",
              "code": 5
            },
            {
              "name": "BAI YUN KUANG QU",
              "code": 6
            },
            {
              "name": "TU MO TE YOU QI",
              "code": 7
            },
            {
              "name": "GU YANG XIAN",
              "code": 8
            },
            {
              "name": "DA ER HAN MAO MING AN LIAN HE QI",
              "code": 9
            }
          ]
        },
        {
          "name": "CHI FENG",
          "code": 5,
          "city": [
            {
              "name": "HONG SHAN QU",
              "code": 1
            },
            {
              "name": "YUAN BAO SHAN QU",
              "code": 2
            },
            {
              "name": "SONG SHAN QU",
              "code": 3
            },
            {
              "name": "A LU KE ER QIN QI",
              "code": 4
            },
            {
              "name": "BA LIN ZUO QI",
              "code": 5
            },
            {
              "name": "BA LIN YOU QI",
              "code": 6
            },
            {
              "name": "LIN XI XIAN",
              "code": 7
            },
            {
              "name": "KE SHI KE TENG QI",
              "code": 8
            },
            {
              "name": "WENG NIU TE QI",
              "code": 9
            },
            {
              "name": "KA LA QIN QI",
              "code": 10
            },
            {
              "name": "NING CHENG XIAN",
              "code": 11
            },
            {
              "name": "AO HAN QI",
              "code": 12
            }
          ]
        },
        {
          "name": "E ER DUO SI",
          "code": 6,
          "city": [
            {
              "name": "DONG SHENG QU",
              "code": 1
            },
            {
              "name": "DA LA TE QI",
              "code": 2
            },
            {
              "name": "ZHUN GE ER QI",
              "code": 3
            },
            {
              "name": "E TUO KE QIAN QI",
              "code": 4
            },
            {
              "name": "E TUO KE QI",
              "code": 5
            },
            {
              "name": "HANG JIN QI",
              "code": 6
            },
            {
              "name": "WU SHEN QI",
              "code": 7
            },
            {
              "name": "YI JIN HUO LUO QI",
              "code": 8
            }
          ]
        },
        {
          "name": "HU LUN BEI ER",
          "code": 7,
          "city": [
            {
              "name": "HAI LA ER QU",
              "code": 1
            },
            {
              "name": "MO LI DA WA",
              "code": 2
            },
            {
              "name": "MAN ZHOU LI SHI",
              "code": 3
            },
            {
              "name": "YA KE SHI SHI",
              "code": 4
            },
            {
              "name": "ZHA LAN TUN SHI",
              "code": 5
            },
            {
              "name": "E ER GU NA SHI",
              "code": 6
            },
            {
              "name": "GEN HE SHI",
              "code": 7
            },
            {
              "name": "A RONG QI",
              "code": 8
            },
            {
              "name": "E LUN CHUN ZI ZHI QI",
              "code": 9
            },
            {
              "name": "E WEN KE ZU ZI ZHI QI",
              "code": 10
            },
            {
              "name": "CHEN BA ER HU QI",
              "code": 11
            },
            {
              "name": "XIN BA ER HU ZUO QI",
              "code": 12
            },
            {
              "name": "XIN BA ER HU YOU QI",
              "code": 13
            }
          ]
        },
        {
          "name": "TONG LIAO",
          "code": 8,
          "city": [
            {
              "name": "KE ER QIN QU",
              "code": 1
            },
            {
              "name": "HUO LIN GUO LE SHI",
              "code": 2
            },
            {
              "name": "KE ER QIN ZUO YI ZHONG QI",
              "code": 3
            },
            {
              "name": "KE ER QIN ZUO YI HOU QI",
              "code": 4
            },
            {
              "name": "KAI LU XIAN",
              "code": 5
            },
            {
              "name": "KU LUN QI",
              "code": 6
            },
            {
              "name": "NAI MAN QI",
              "code": 7
            },
            {
              "name": "ZA LU TE QI",
              "code": 8
            }
          ]
        },
        {
          "name": "WU HAI",
          "code": 9,
          "city": [
            {
              "name": "HAI BO WAN QU",
              "code": 1
            },
            {
              "name": "WU DA QU",
              "code": 2
            },
            {
              "name": "HAI NAN QU",
              "code": 3
            }
          ]
        },
        {
          "name": "WU LAN CHA BU SHI",
          "code": 10,
          "city": [
            {
              "name": "HUA DE XIAN",
              "code": 1
            },
            {
              "name": "JI NING QU",
              "code": 2
            },
            {
              "name": "FENG ZHEN SHI",
              "code": 3
            },
            {
              "name": "ZHUO ZI XIAN",
              "code": 4
            },
            {
              "name": "SHANG DU XIAN",
              "code": 5
            },
            {
              "name": "XING HE XIAN",
              "code": 6
            },
            {
              "name": "LIANG CHENG XIAN",
              "code": 7
            },
            {
              "name": "CHA HA ER YOU YI QIAN QI",
              "code": 8
            },
            {
              "name": "CHA HA ER YOU YI ZHONG QI",
              "code": 9
            },
            {
              "name": "CHA HA ER YOU YI HOU QI",
              "code": 10
            },
            {
              "name": "SI ZI WANG QI",
              "code": 11
            }
          ]
        },
        {
          "name": "XI LIN GUO LE MENG",
          "code": 11,
          "city": [
            {
              "name": "ER LIAN HAO TE SHI",
              "code": 1
            },
            {
              "name": "XI LIN HAO TE SHI",
              "code": 2
            },
            {
              "name": "A BA GA QI",
              "code": 3
            },
            {
              "name": "SU NI TE ZUO QI",
              "code": 4
            },
            {
              "name": "SU NI TE YOU QI",
              "code": 5
            },
            {
              "name": "DONG WU ZHU MU QIN QI",
              "code": 6
            },
            {
              "name": "XI WU ZHU MU QIN QI",
              "code": 7
            },
            {
              "name": "TAI PU SI QI",
              "code": 8
            },
            {
              "name": "XIANG HUANG QI",
              "code": 9
            },
            {
              "name": "ZHENG XIANG BAI QI",
              "code": 10
            },
            {
              "name": "ZHENG LAN QI",
              "code": 11
            },
            {
              "name": "DUO LUN XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "XING AN MENG",
          "code": 12,
          "city": [
            {
              "name": "WU LAN HAO TE SHI",
              "code": 1
            },
            {
              "name": "A ER SHAN SHI",
              "code": 2
            },
            {
              "name": "KE ER QIN YOU YI QIAN QI",
              "code": 3
            },
            {
              "name": "KE ER QIN YOU YI ZHONG QI",
              "code": 4
            },
            {
              "name": "ZHA LAI TE QI",
              "code": 5
            },
            {
              "name": "TU QUAN XIAN",
              "code": 6
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "NING XIA",
      "code": 19,
      "state": [
        {
          "name": "YIN CHUAN",
          "code": 1,
          "city": [
            {
              "name": "XI XIA QU",
              "code": 1
            },
            {
              "name": "JIN FENG QU",
              "code": 2
            },
            {
              "name": "XING QING QU",
              "code": 3
            },
            {
              "name": "LING WU SHI",
              "code": 4
            },
            {
              "name": "YONG NING XIAN",
              "code": 5
            },
            {
              "name": "HE LAN XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "GU YUAN",
          "code": 2,
          "city": [
            {
              "name": "YUAN ZHOU QU",
              "code": 1
            },
            {
              "name": "HAI YUAN XIAN",
              "code": 2
            },
            {
              "name": "XI JI XIAN",
              "code": 3
            },
            {
              "name": "LONG DE XIAN",
              "code": 4
            },
            {
              "name": "JING YUAN XIAN",
              "code": 5
            },
            {
              "name": "PENG YANG XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "SHI ZUI SHAN",
          "code": 3,
          "city": [
            {
              "name": "HUI NONG XIAN",
              "code": 1
            },
            {
              "name": "DA WU KOU QU",
              "code": 2
            },
            {
              "name": "HUI NONG QU",
              "code": 3
            },
            {
              "name": "TAO LE XIAN",
              "code": 4
            },
            {
              "name": "PING LUO XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "WU ZHONG",
          "code": 4,
          "city": [
            {
              "name": "LI TONG QU",
              "code": 1
            },
            {
              "name": "ZHONG WEI XIAN",
              "code": 2
            },
            {
              "name": "QING TONG XIA SHI",
              "code": 3
            },
            {
              "name": "ZHONG NING XIAN",
              "code": 4
            },
            {
              "name": "YAN CHI XIAN",
              "code": 5
            },
            {
              "name": "TONG XIN XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "ZHONG WEI",
          "code": 5,
          "city": [
            {
              "name": "SHA PO TOU QU",
              "code": 1
            },
            {
              "name": "HAI YUAN XIAN",
              "code": 2
            },
            {
              "name": "ZHONG NING XIAN",
              "code": 3
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "QING HAI",
      "code": 20,
      "state": [
        {
          "name": "XI NING",
          "code": 1,
          "city": [
            {
              "name": "CHENG ZHONG QU",
              "code": 1
            },
            {
              "name": "CHENG DONG QU",
              "code": 2
            },
            {
              "name": "CHENG XI QU",
              "code": 3
            },
            {
              "name": "CHENG BEI QU",
              "code": 4
            },
            {
              "name": "HUANG ZHONG XIAN",
              "code": 5
            },
            {
              "name": "HUANG YUAN XIAN",
              "code": 6
            },
            {
              "name": "DA TONG",
              "code": 7
            }
          ]
        },
        {
          "name": "GUO LUO",
          "code": 2,
          "city": [
            {
              "name": "MA QIN XIAN",
              "code": 1
            },
            {
              "name": "BAN MA XIAN",
              "code": 2
            },
            {
              "name": "GAN DE XIAN",
              "code": 3
            },
            {
              "name": "DA RI XIAN",
              "code": 4
            },
            {
              "name": "JIU ZHI XIAN",
              "code": 5
            },
            {
              "name": "MA DUO XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "HAI BEI",
          "code": 3,
          "city": [
            {
              "name": "HAI YAN XIAN",
              "code": 1
            },
            {
              "name": "QI LIAN XIAN",
              "code": 2
            },
            {
              "name": "GANG CHA XIAN",
              "code": 3
            },
            {
              "name": "MEN YUAN",
              "code": 4
            }
          ]
        },
        {
          "name": "HAI DONG",
          "code": 4,
          "city": [
            {
              "name": "PING AN XIAN",
              "code": 1
            },
            {
              "name": "LE DU XIAN",
              "code": 2
            },
            {
              "name": "MIN HE",
              "code": 3
            },
            {
              "name": "HU ZHU",
              "code": 4
            },
            {
              "name": "HUA LONG",
              "code": 5
            },
            {
              "name": "XUN HUA",
              "code": 6
            }
          ]
        },
        {
          "name": "HAI NAN",
          "code": 5,
          "city": [
            {
              "name": "GONG HE XIAN",
              "code": 1
            },
            {
              "name": "TONG DE XIAN",
              "code": 2
            },
            {
              "name": "GUI DE XIAN",
              "code": 3
            },
            {
              "name": "XING HAI XIAN",
              "code": 4
            },
            {
              "name": "GUI NAN XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "HAI XI",
          "code": 6,
          "city": [
            {
              "name": "DE LING HA SHI",
              "code": 1
            },
            {
              "name": "GE ER MU SHI",
              "code": 2
            },
            {
              "name": "WU LAN XIAN",
              "code": 3
            },
            {
              "name": "DU LAN XIAN",
              "code": 4
            },
            {
              "name": "TIAN JUN XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "HUANG NAN",
          "code": 7,
          "city": [
            {
              "name": "TONG REN XIAN",
              "code": 1
            },
            {
              "name": "JIAN ZHA XIAN",
              "code": 2
            },
            {
              "name": "ZE KU XIAN",
              "code": 3
            },
            {
              "name": "HE NAN MENG GU ZU ZI ZHI XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "YU SHU",
          "code": 8,
          "city": [
            {
              "name": "YU SHU XIAN",
              "code": 1
            },
            {
              "name": "ZA DUO XIAN",
              "code": 2
            },
            {
              "name": "CHEN DUO XIAN",
              "code": 3
            },
            {
              "name": "ZHI DUO XIAN",
              "code": 4
            },
            {
              "name": "NANG QIAN XIAN",
              "code": 5
            },
            {
              "name": "QU MA LAI XIAN",
              "code": 6
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "SHAN DONG",
      "code": 21,
      "state": [
        {
          "name": "JI NAN",
          "code": 1,
          "city": [
            {
              "name": "SHI ZHONG QU",
              "code": 1
            },
            {
              "name": "LI XIA QU",
              "code": 2
            },
            {
              "name": "TIAN QIAO QU",
              "code": 3
            },
            {
              "name": "HUAI YIN QU",
              "code": 4
            },
            {
              "name": "LI CHENG QU",
              "code": 5
            },
            {
              "name": "CHANG QING QU",
              "code": 6
            },
            {
              "name": "ZHANG QIU SHI",
              "code": 7
            },
            {
              "name": "PING YIN XIAN",
              "code": 8
            },
            {
              "name": "JI YANG XIAN",
              "code": 9
            },
            {
              "name": "SHANG HE XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "QING DAO",
          "code": 2,
          "city": [
            {
              "name": "SHI NAN QU",
              "code": 1
            },
            {
              "name": "SHI BEI QU",
              "code": 2
            },
            {
              "name": "CHENG YANG QU",
              "code": 3
            },
            {
              "name": "SI FANG QU",
              "code": 4
            },
            {
              "name": "LI CANG QU",
              "code": 5
            },
            {
              "name": "HUANG DAO QU",
              "code": 6
            },
            {
              "name": "LAO SHAN QU",
              "code": 7
            },
            {
              "name": "JIAO ZHOU SHI",
              "code": 8
            },
            {
              "name": "JI MO SHI",
              "code": 9
            },
            {
              "name": "PING DU SHI",
              "code": 10
            },
            {
              "name": "JIAO NAN SHI",
              "code": 11
            },
            {
              "name": "LAI XI SHI",
              "code": 12
            }
          ]
        },
        {
          "name": "BIN ZHOU",
          "code": 3,
          "city": [
            {
              "name": "BIN CHENG QU",
              "code": 1
            },
            {
              "name": "HUI MIN XIAN",
              "code": 2
            },
            {
              "name": "YANG XIN XIAN",
              "code": 3
            },
            {
              "name": "WU DI XIAN",
              "code": 4
            },
            {
              "name": "ZHAN HUA XIAN",
              "code": 5
            },
            {
              "name": "BO XING XIAN",
              "code": 6
            },
            {
              "name": "ZOU PING XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "DE ZHOU",
          "code": 4,
          "city": [
            {
              "name": "DE CHENG QU",
              "code": 1
            },
            {
              "name": "LING XIAN",
              "code": 2
            },
            {
              "name": "LE LING SHI",
              "code": 3
            },
            {
              "name": "YU CHENG SHI",
              "code": 4
            },
            {
              "name": "NING JIN XIAN",
              "code": 5
            },
            {
              "name": "QING YUN XIAN",
              "code": 6
            },
            {
              "name": "LIN YI XIAN",
              "code": 7
            },
            {
              "name": "QI HE XIAN",
              "code": 8
            },
            {
              "name": "PING YUAN XIAN",
              "code": 9
            },
            {
              "name": "XIA JIN XIAN",
              "code": 10
            },
            {
              "name": "WU CHENG XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "DONG YING",
          "code": 5,
          "city": [
            {
              "name": "DONG YING QU",
              "code": 1
            },
            {
              "name": "HE KOU QU",
              "code": 2
            },
            {
              "name": "KEN LI XIAN",
              "code": 3
            },
            {
              "name": "LI JIN XIAN",
              "code": 4
            },
            {
              "name": "GUANG RAO XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "HE ZE",
          "code": 6,
          "city": [
            {
              "name": "MU DAN QU",
              "code": 1
            },
            {
              "name": "CAO XIAN",
              "code": 2
            },
            {
              "name": "SHAN XIAN",
              "code": 3
            },
            {
              "name": "CHENG WU XIAN",
              "code": 4
            },
            {
              "name": "JU YE XIAN",
              "code": 5
            },
            {
              "name": "YUN CHENG XIAN",
              "code": 6
            },
            {
              "name": "JUAN CHENG XIAN",
              "code": 7
            },
            {
              "name": "DING TAO XIAN",
              "code": 8
            },
            {
              "name": "DONG MING XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "JI NING",
          "code": 7,
          "city": [
            {
              "name": "SHI ZHONG QU",
              "code": 1
            },
            {
              "name": "REN CHENG QU",
              "code": 2
            },
            {
              "name": "QU FU SHI",
              "code": 3
            },
            {
              "name": "YAN ZHOU SHI",
              "code": 4
            },
            {
              "name": "ZOU CHENG SHI",
              "code": 5
            },
            {
              "name": "WEI SHAN XIAN",
              "code": 6
            },
            {
              "name": "YU TAI XIAN",
              "code": 7
            },
            {
              "name": "JIN XIANG XIAN",
              "code": 8
            },
            {
              "name": "JIA XIANG XIAN",
              "code": 9
            },
            {
              "name": "WEN SHANG XIAN",
              "code": 10
            },
            {
              "name": "SI SHUI XIAN",
              "code": 11
            },
            {
              "name": "LIANG SHAN XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "LAI WU",
          "code": 8,
          "city": [
            {
              "name": "LAI CHENG QU",
              "code": 1
            },
            {
              "name": "GANG CHENG QU",
              "code": 2
            }
          ]
        },
        {
          "name": "LIAO CHENG",
          "code": 9,
          "city": [
            {
              "name": "DONG CHANG FU QU",
              "code": 1
            },
            {
              "name": "LIN QING SHI",
              "code": 2
            },
            {
              "name": "YANG GU XIAN",
              "code": 3
            },
            {
              "name": "SHEN XIAN",
              "code": 4
            },
            {
              "name": "CHI PING XIAN",
              "code": 5
            },
            {
              "name": "DONG E XIAN",
              "code": 6
            },
            {
              "name": "GUAN XIAN",
              "code": 7
            },
            {
              "name": "GAO TANG XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "LIN YI",
          "code": 10,
          "city": [
            {
              "name": "LAN SHAN QU",
              "code": 1
            },
            {
              "name": "LUO ZHUANG QU",
              "code": 2
            },
            {
              "name": "HE DONG QU",
              "code": 3
            },
            {
              "name": "YI NAN XIAN",
              "code": 4
            },
            {
              "name": "TAN CHENG XIAN",
              "code": 5
            },
            {
              "name": "YI SHUI XIAN",
              "code": 6
            },
            {
              "name": "CANG SHAN XIAN",
              "code": 7
            },
            {
              "name": "FEI XIAN",
              "code": 8
            },
            {
              "name": "PING YI XIAN",
              "code": 9
            },
            {
              "name": "JU NAN XIAN",
              "code": 10
            },
            {
              "name": "MENG YIN XIAN",
              "code": 11
            },
            {
              "name": "LIN SHU XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "RI ZHAO",
          "code": 11,
          "city": [
            {
              "name": "DONG GANG QU",
              "code": 1
            },
            {
              "name": "LAN SHAN QU",
              "code": 2
            },
            {
              "name": "WU LIAN XIAN",
              "code": 3
            },
            {
              "name": "JU XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "TAI AN",
          "code": 12,
          "city": [
            {
              "name": "TAI SHAN QU",
              "code": 1
            },
            {
              "name": "DAI YUE QU",
              "code": 2
            },
            {
              "name": "XIN TAI SHI",
              "code": 3
            },
            {
              "name": "FEI CHENG SHI",
              "code": 4
            },
            {
              "name": "NING YANG XIAN",
              "code": 5
            },
            {
              "name": "DONG PING XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "WEI HAI",
          "code": 13,
          "city": [
            {
              "name": "RONG CHENG SHI",
              "code": 1
            },
            {
              "name": "RU SHAN SHI",
              "code": 2
            },
            {
              "name": "HUAN CUI QU",
              "code": 3
            },
            {
              "name": "WEN DENG SHI",
              "code": 4
            }
          ]
        },
        {
          "name": "WEI FANG",
          "code": 14,
          "city": [
            {
              "name": "WEI CHENG QU",
              "code": 1
            },
            {
              "name": "HAN TING QU",
              "code": 2
            },
            {
              "name": "FANG ZI QU",
              "code": 3
            },
            {
              "name": "KUI WEN QU",
              "code": 4
            },
            {
              "name": "QING ZHOU SHI",
              "code": 5
            },
            {
              "name": "ZHU CHENG SHI",
              "code": 6
            },
            {
              "name": "SHOU GUANG SHI",
              "code": 7
            },
            {
              "name": "AN QIU SHI",
              "code": 8
            },
            {
              "name": "GAO MI SHI",
              "code": 9
            },
            {
              "name": "CHANG YI SHI",
              "code": 10
            },
            {
              "name": "LIN QU XIAN",
              "code": 11
            },
            {
              "name": "CHANG LE XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "YAN TAI",
          "code": 15,
          "city": [
            {
              "name": "ZHI FU QU",
              "code": 1
            },
            {
              "name": "FU SHAN QU",
              "code": 2
            },
            {
              "name": "MU PING QU",
              "code": 3
            },
            {
              "name": "LAI SHAN QU",
              "code": 4
            },
            {
              "name": "KAI FA QU",
              "code": 5
            },
            {
              "name": "LONG KOU SHI",
              "code": 6
            },
            {
              "name": "LAI YANG SHI",
              "code": 7
            },
            {
              "name": "LAI ZHOU SHI",
              "code": 8
            },
            {
              "name": "PENG LAI SHI",
              "code": 9
            },
            {
              "name": "ZHAO YUAN SHI",
              "code": 10
            },
            {
              "name": "XI XIA SHI",
              "code": 11
            },
            {
              "name": "HAI YANG SHI",
              "code": 12
            },
            {
              "name": "CHANG DAO XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "ZAO ZHUANG",
          "code": 16,
          "city": [
            {
              "name": "SHI ZHONG QU",
              "code": 1
            },
            {
              "name": "SHAN TING QU",
              "code": 2
            },
            {
              "name": "YI CHENG QU",
              "code": 3
            },
            {
              "name": "TAI ER ZHUANG QU",
              "code": 4
            },
            {
              "name": "XUE CHENG QU",
              "code": 5
            },
            {
              "name": "TENG ZHOU SHI",
              "code": 6
            }
          ]
        },
        {
          "name": "ZI BO",
          "code": 17,
          "city": [
            {
              "name": "ZHANG DIAN QU",
              "code": 1
            },
            {
              "name": "LIN ZI QU",
              "code": 2
            },
            {
              "name": "ZI CHUAN QU",
              "code": 3
            },
            {
              "name": "BO SHAN QU",
              "code": 4
            },
            {
              "name": "ZHOU CUN QU",
              "code": 5
            },
            {
              "name": "HUAN TAI XIAN",
              "code": 6
            },
            {
              "name": "GAO QING XIAN",
              "code": 7
            },
            {
              "name": "YI YUAN XIAN",
              "code": 8
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "SHAN XI",
      "code": 22,
      "state": [
        {
          "name": "TAI YUAN",
          "code": 1,
          "city": [
            {
              "name": "XING HUA LING QU",
              "code": 1
            },
            {
              "name": "XIAO DIAN QU",
              "code": 2
            },
            {
              "name": "YING ZE QU",
              "code": 3
            },
            {
              "name": "JIAN CAO PING QU",
              "code": 4
            },
            {
              "name": "WAN BO LIN QU",
              "code": 5
            },
            {
              "name": "JIN YUAN QU",
              "code": 6
            },
            {
              "name": "GAO XIN KAI FA QU",
              "code": 7
            },
            {
              "name": "MIN YING JING JI KAI FA QU",
              "code": 8
            },
            {
              "name": "JING JI JI SHU KAI FA QU",
              "code": 9
            },
            {
              "name": "QING XU XIAN",
              "code": 10
            },
            {
              "name": "YANG QU XIAN",
              "code": 11
            },
            {
              "name": "LOU FAN XIAN",
              "code": 12
            },
            {
              "name": "GU JIAO SHI",
              "code": 13
            }
          ]
        },
        {
          "name": "CHANG ZHI",
          "code": 2,
          "city": [
            {
              "name": "CHENG QU",
              "code": 1
            },
            {
              "name": "JIAO QU",
              "code": 2
            },
            {
              "name": "QIN XIAN",
              "code": 3
            },
            {
              "name": "LU CHENG SHI",
              "code": 4
            },
            {
              "name": "CHANG ZHI XIAN",
              "code": 5
            },
            {
              "name": "XIANG YUAN XIAN",
              "code": 6
            },
            {
              "name": "TUN LIU XIAN",
              "code": 7
            },
            {
              "name": "PING SHUN XIAN",
              "code": 8
            },
            {
              "name": "LI CHENG XIAN",
              "code": 9
            },
            {
              "name": "HU GUAN XIAN",
              "code": 10
            },
            {
              "name": "CHANG ZI XIAN",
              "code": 11
            },
            {
              "name": "WU XIANG XIAN",
              "code": 12
            },
            {
              "name": "QIN YUAN XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "DA TONG",
          "code": 3,
          "city": [
            {
              "name": "CHENG QU",
              "code": 1
            },
            {
              "name": "KUANG QU",
              "code": 2
            },
            {
              "name": "NAN JIAO QU",
              "code": 3
            },
            {
              "name": "XIN RONG QU",
              "code": 4
            },
            {
              "name": "YANG GAO XIAN",
              "code": 5
            },
            {
              "name": "TIAN ZHEN XIAN",
              "code": 6
            },
            {
              "name": "GUANG LING XIAN",
              "code": 7
            },
            {
              "name": "LING QIU XIAN",
              "code": 8
            },
            {
              "name": "HUN YUAN XIAN",
              "code": 9
            },
            {
              "name": "ZUO YUN XIAN",
              "code": 10
            },
            {
              "name": "DA TONG XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "JIN CHENG",
          "code": 4,
          "city": [
            {
              "name": "CHENG QU",
              "code": 1
            },
            {
              "name": "GAO PING SHI",
              "code": 2
            },
            {
              "name": "QIN SHUI XIAN",
              "code": 3
            },
            {
              "name": "YANG CHENG XIAN",
              "code": 4
            },
            {
              "name": "LING CHUAN XIAN",
              "code": 5
            },
            {
              "name": "ZE ZHOU XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "JIN ZHONG",
          "code": 5,
          "city": [
            {
              "name": "YU CI QU",
              "code": 1
            },
            {
              "name": "JIE XIU SHI",
              "code": 2
            },
            {
              "name": "YU SHE XIAN",
              "code": 3
            },
            {
              "name": "ZUO QUAN XIAN",
              "code": 4
            },
            {
              "name": "HE SHUN XIAN",
              "code": 5
            },
            {
              "name": "XI YANG XIAN",
              "code": 6
            },
            {
              "name": "SHOU YANG XIAN",
              "code": 7
            },
            {
              "name": "TAI GU XIAN",
              "code": 8
            },
            {
              "name": "QI XIAN",
              "code": 9
            },
            {
              "name": "PING YAO XIAN",
              "code": 10
            },
            {
              "name": "LING SHI XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "LIN FEN",
          "code": 6,
          "city": [
            {
              "name": "YAO DU QU",
              "code": 1
            },
            {
              "name": "HOU MA SHI",
              "code": 2
            },
            {
              "name": "HUO ZHOU SHI",
              "code": 3
            },
            {
              "name": "QU WO XIAN",
              "code": 4
            },
            {
              "name": "YI CHENG XIAN",
              "code": 5
            },
            {
              "name": "XIANG FEN XIAN",
              "code": 6
            },
            {
              "name": "HONG TONG XIAN",
              "code": 7
            },
            {
              "name": "JI XIAN",
              "code": 8
            },
            {
              "name": "AN ZE XIAN",
              "code": 9
            },
            {
              "name": "FU SHAN XIAN",
              "code": 10
            },
            {
              "name": "GU XIAN",
              "code": 11
            },
            {
              "name": "XIANG NING XIAN",
              "code": 12
            },
            {
              "name": "DA NING XIAN",
              "code": 13
            },
            {
              "name": "XI XIAN",
              "code": 14
            },
            {
              "name": "YONG HE XIAN",
              "code": 15
            },
            {
              "name": "PU XIAN",
              "code": 16
            },
            {
              "name": "FEN XI XIAN",
              "code": 17
            }
          ]
        },
        {
          "name": "LYU LIANG",
          "code": 7,
          "city": [
            {
              "name": "LI SHI SHI",
              "code": 1
            },
            {
              "name": "LI SHI QU",
              "code": 2
            },
            {
              "name": "XIAO YI SHI",
              "code": 3
            },
            {
              "name": "FEN YANG SHI",
              "code": 4
            },
            {
              "name": "WEN SHUI XIAN",
              "code": 5
            },
            {
              "name": "JIAO CHENG XIAN",
              "code": 6
            },
            {
              "name": "XING XIAN",
              "code": 7
            },
            {
              "name": "LIN XIAN",
              "code": 8
            },
            {
              "name": "LIU LIN XIAN",
              "code": 9
            },
            {
              "name": "SHI LOU XIAN",
              "code": 10
            },
            {
              "name": "LAN XIAN",
              "code": 11
            },
            {
              "name": "FANG SHAN XIAN",
              "code": 12
            },
            {
              "name": "ZHONG YANG XIAN",
              "code": 13
            },
            {
              "name": "JIAO KOU XIAN",
              "code": 14
            }
          ]
        },
        {
          "name": "SHUO ZHOU",
          "code": 8,
          "city": [
            {
              "name": "SHUO CHENG QU",
              "code": 1
            },
            {
              "name": "PING LU QU",
              "code": 2
            },
            {
              "name": "SHAN YIN XIAN",
              "code": 3
            },
            {
              "name": "YING XIAN",
              "code": 4
            },
            {
              "name": "YOU YU XIAN",
              "code": 5
            },
            {
              "name": "HUAI REN XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "XIN ZHOU",
          "code": 9,
          "city": [
            {
              "name": "XIN FU QU",
              "code": 1
            },
            {
              "name": "YUAN PING SHI",
              "code": 2
            },
            {
              "name": "DING XIANG XIAN",
              "code": 3
            },
            {
              "name": "WU TAI XIAN",
              "code": 4
            },
            {
              "name": "DAI XIAN",
              "code": 5
            },
            {
              "name": "FAN SHI XIAN",
              "code": 6
            },
            {
              "name": "NING WU XIAN",
              "code": 7
            },
            {
              "name": "JING LE XIAN",
              "code": 8
            },
            {
              "name": "SHEN CHI XIAN",
              "code": 9
            },
            {
              "name": "WU ZHAI XIAN",
              "code": 10
            },
            {
              "name": "KE LAN XIAN",
              "code": 11
            },
            {
              "name": "HE QU XIAN",
              "code": 12
            },
            {
              "name": "BAO DE XIAN",
              "code": 13
            },
            {
              "name": "PIAN GUAN XIAN",
              "code": 14
            }
          ]
        },
        {
          "name": "YANG QUAN",
          "code": 10,
          "city": [
            {
              "name": "CHENG QU",
              "code": 1
            },
            {
              "name": "KUANG QU",
              "code": 2
            },
            {
              "name": "JIAO QU",
              "code": 3
            },
            {
              "name": "PING DING XIAN",
              "code": 4
            },
            {
              "name": "YU XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "YUN CHENG",
          "code": 11,
          "city": [
            {
              "name": "YAN HU QU",
              "code": 1
            },
            {
              "name": "YONG JI SHI",
              "code": 2
            },
            {
              "name": "HE JIN SHI",
              "code": 3
            },
            {
              "name": "LIN YI XIAN",
              "code": 4
            },
            {
              "name": "WAN RONG XIAN",
              "code": 5
            },
            {
              "name": "WEN XI XIAN",
              "code": 6
            },
            {
              "name": "JI SHAN XIAN",
              "code": 7
            },
            {
              "name": "XIN JIANG XIAN",
              "code": 8
            },
            {
              "name": "JIANG XIAN",
              "code": 9
            },
            {
              "name": "YUAN QU XIAN",
              "code": 10
            },
            {
              "name": "XIA XIAN",
              "code": 11
            },
            {
              "name": "PING LU XIAN",
              "code": 12
            },
            {
              "name": "RUI CHENG XIAN",
              "code": 13
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "SHAN XI",
      "code": 23,
      "state": [
        {
          "name": "XI AN",
          "code": 1,
          "city": [
            {
              "name": "LIAN HU QU",
              "code": 1
            },
            {
              "name": "XIN CHENG QU",
              "code": 2
            },
            {
              "name": "BEI LIN QU",
              "code": 3
            },
            {
              "name": "YAN TA QU",
              "code": 4
            },
            {
              "name": "BA QIAO QU",
              "code": 5
            },
            {
              "name": "WEI YANG QU",
              "code": 6
            },
            {
              "name": "YAN LIANG QU",
              "code": 7
            },
            {
              "name": "LIN TONG QU",
              "code": 8
            },
            {
              "name": "CHANG AN QU",
              "code": 9
            },
            {
              "name": "LAN TIAN XIAN",
              "code": 10
            },
            {
              "name": "ZHOU ZHI XIAN",
              "code": 11
            },
            {
              "name": "HU XIAN",
              "code": 12
            },
            {
              "name": "GAO LING XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "AN KANG",
          "code": 2,
          "city": [
            {
              "name": "HAN BIN QU",
              "code": 1
            },
            {
              "name": "HAN YIN XIAN",
              "code": 2
            },
            {
              "name": "SHI QUAN XIAN",
              "code": 3
            },
            {
              "name": "NING SHAN XIAN",
              "code": 4
            },
            {
              "name": "ZI YANG XIAN",
              "code": 5
            },
            {
              "name": "LAN GAO XIAN",
              "code": 6
            },
            {
              "name": "PING LI XIAN",
              "code": 7
            },
            {
              "name": "ZHEN PING XIAN",
              "code": 8
            },
            {
              "name": "XUN YANG XIAN",
              "code": 9
            },
            {
              "name": "BAI HE XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "BAO JI",
          "code": 3,
          "city": [
            {
              "name": "CHEN CANG QU",
              "code": 1
            },
            {
              "name": "WEI BIN QU",
              "code": 2
            },
            {
              "name": "JIN TAI QU",
              "code": 3
            },
            {
              "name": "FENG XIANG XIAN",
              "code": 4
            },
            {
              "name": "QI SHAN XIAN",
              "code": 5
            },
            {
              "name": "FU FENG XIAN",
              "code": 6
            },
            {
              "name": "MEI XIAN",
              "code": 7
            },
            {
              "name": "LONG XIAN",
              "code": 8
            },
            {
              "name": "QIAN YANG XIAN",
              "code": 9
            },
            {
              "name": "LIN YOU XIAN",
              "code": 10
            },
            {
              "name": "FENG XIAN",
              "code": 11
            },
            {
              "name": "TAI BAI XIAN",
              "code": 12
            }
          ]
        },
        {
          "name": "HAN ZHONG",
          "code": 4,
          "city": [
            {
              "name": "HAN TAI QU",
              "code": 1
            },
            {
              "name": "NAN ZHENG XIAN",
              "code": 2
            },
            {
              "name": "CHENG GU XIAN",
              "code": 3
            },
            {
              "name": "YANG XIAN",
              "code": 4
            },
            {
              "name": "XI XIANG XIAN",
              "code": 5
            },
            {
              "name": "MIAN XIAN",
              "code": 6
            },
            {
              "name": "NING QIANG XIAN",
              "code": 7
            },
            {
              "name": "LUE YANG XIAN",
              "code": 8
            },
            {
              "name": "ZHEN BA XIAN",
              "code": 9
            },
            {
              "name": "LIU BA XIAN",
              "code": 10
            },
            {
              "name": "FO PING XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "SHANG LUO",
          "code": 5,
          "city": [
            {
              "name": "SHANG ZHOU QU",
              "code": 1
            },
            {
              "name": "LUO NAN XIAN",
              "code": 2
            },
            {
              "name": "DAN FENG XIAN",
              "code": 3
            },
            {
              "name": "SHANG NAN XIAN",
              "code": 4
            },
            {
              "name": "SHAN YANG XIAN",
              "code": 5
            },
            {
              "name": "ZHEN AN XIAN",
              "code": 6
            },
            {
              "name": "ZHA SHUI XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "TONG CHUAN",
          "code": 6,
          "city": [
            {
              "name": "YAO ZHOU QU",
              "code": 1
            },
            {
              "name": "WANG YI QU",
              "code": 2
            },
            {
              "name": "YIN TAI QU",
              "code": 3
            },
            {
              "name": "YI JUN XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "WEI NAN",
          "code": 7,
          "city": [
            {
              "name": "LIN WEI QU",
              "code": 1
            },
            {
              "name": "HAN CHENG SHI",
              "code": 2
            },
            {
              "name": "HUA YIN SHI",
              "code": 3
            },
            {
              "name": "HUA XIAN",
              "code": 4
            },
            {
              "name": "TONG GUAN XIAN",
              "code": 5
            },
            {
              "name": "DA LI XIAN",
              "code": 6
            },
            {
              "name": "HE YANG XIAN",
              "code": 7
            },
            {
              "name": "CHENG CHENG XIAN",
              "code": 8
            },
            {
              "name": "PU CHENG XIAN",
              "code": 9
            },
            {
              "name": "BAI SHUI XIAN",
              "code": 10
            },
            {
              "name": "FU PING XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "XIAN YANG",
          "code": 8,
          "city": [
            {
              "name": "QIN DU QU",
              "code": 1
            },
            {
              "name": "WEI CHENG QU",
              "code": 2
            },
            {
              "name": "YANG LING QU",
              "code": 3
            },
            {
              "name": "XING PING SHI",
              "code": 4
            },
            {
              "name": "SAN YUAN XIAN",
              "code": 5
            },
            {
              "name": "JING YANG XIAN",
              "code": 6
            },
            {
              "name": "QIAN XIAN",
              "code": 7
            },
            {
              "name": "LI QUAN XIAN",
              "code": 8
            },
            {
              "name": "YONG SHOU XIAN",
              "code": 9
            },
            {
              "name": "BIN XIAN",
              "code": 10
            },
            {
              "name": "CHANG WU XIAN",
              "code": 11
            },
            {
              "name": "XUN YI XIAN",
              "code": 12
            },
            {
              "name": "CHUN HUA XIAN",
              "code": 13
            },
            {
              "name": "WU GONG XIAN",
              "code": 14
            }
          ]
        },
        {
          "name": "YAN AN",
          "code": 9,
          "city": [
            {
              "name": "WU QI XIAN",
              "code": 1
            },
            {
              "name": "BAO TA QU",
              "code": 2
            },
            {
              "name": "YAN CHANG XIAN",
              "code": 3
            },
            {
              "name": "YAN CHUAN XIAN",
              "code": 4
            },
            {
              "name": "ZI CHANG XIAN",
              "code": 5
            },
            {
              "name": "AN SAI XIAN",
              "code": 6
            },
            {
              "name": "ZHI DAN XIAN",
              "code": 7
            },
            {
              "name": "GAN QUAN XIAN",
              "code": 8
            },
            {
              "name": "FU XIAN",
              "code": 9
            },
            {
              "name": "LUO CHUAN XIAN",
              "code": 10
            },
            {
              "name": "YI CHUAN XIAN",
              "code": 11
            },
            {
              "name": "HUANG LONG XIAN",
              "code": 12
            },
            {
              "name": "HUANG LING XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "YU LIN",
          "code": 10,
          "city": [
            {
              "name": "YU YANG QU",
              "code": 1
            },
            {
              "name": "SHEN MU XIAN",
              "code": 2
            },
            {
              "name": "FU GU XIAN",
              "code": 3
            },
            {
              "name": "HENG SHAN XIAN",
              "code": 4
            },
            {
              "name": "JING BIAN XIAN",
              "code": 5
            },
            {
              "name": "DING BIAN XIAN",
              "code": 6
            },
            {
              "name": "SUI DE XIAN",
              "code": 7
            },
            {
              "name": "MI ZHI XIAN",
              "code": 8
            },
            {
              "name": "JIA XIAN",
              "code": 9
            },
            {
              "name": "WU BU XIAN",
              "code": 10
            },
            {
              "name": "QING JIAN XIAN",
              "code": 11
            },
            {
              "name": "ZI ZHOU XIAN",
              "code": 12
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "SHANG HAI",
      "code": 24,
      "state": [
        {
          "name": "SHANG HAI",
          "code": 1,
          "city": [
            {
              "name": "CHANG NING QU",
              "code": 1
            },
            {
              "name": "ZHA BEI QU",
              "code": 2
            },
            {
              "name": "MIN HANG QU",
              "code": 3
            },
            {
              "name": "XU HUI QU",
              "code": 4
            },
            {
              "name": "PU DONG XIN QU",
              "code": 5
            },
            {
              "name": "YANG PU QU",
              "code": 6
            },
            {
              "name": "PU TUO QU",
              "code": 7
            },
            {
              "name": "JING AN QU",
              "code": 8
            },
            {
              "name": "LU WAN QU",
              "code": 9
            },
            {
              "name": "HONG KOU QU",
              "code": 10
            },
            {
              "name": "HUANG PU QU",
              "code": 11
            },
            {
              "name": "NAN HUI QU",
              "code": 12
            },
            {
              "name": "SONG JIANG QU",
              "code": 13
            },
            {
              "name": "JIA DING QU",
              "code": 14
            },
            {
              "name": "BAO SHAN QU",
              "code": 15
            },
            {
              "name": "QING PU QU",
              "code": 16
            },
            {
              "name": "JIN SHAN QU",
              "code": 17
            },
            {
              "name": "FENG XIAN QU",
              "code": 18
            },
            {
              "name": "CHONG MING XIAN",
              "code": 19
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "SI CHUAN",
      "code": 25,
      "state": [
        {
          "name": "CHENG DU",
          "code": 1,
          "city": [
            {
              "name": "QING YANG QU",
              "code": 1
            },
            {
              "name": "JIN JIANG QU",
              "code": 2
            },
            {
              "name": "JIN NIU QU",
              "code": 3
            },
            {
              "name": "WU HOU QU",
              "code": 4
            },
            {
              "name": "CHENG HUA QU",
              "code": 5
            },
            {
              "name": "LONG QUAN YI QU",
              "code": 6
            },
            {
              "name": "QING BAI JIANG QU",
              "code": 7
            },
            {
              "name": "XIN DU QU",
              "code": 8
            },
            {
              "name": "WEN JIANG QU",
              "code": 9
            },
            {
              "name": "GAO XIN QU",
              "code": 10
            },
            {
              "name": "GAO XIN XI QU",
              "code": 11
            },
            {
              "name": "DU JIANG YAN SHI",
              "code": 12
            },
            {
              "name": "PENG ZHOU SHI",
              "code": 13
            },
            {
              "name": "QIONG LAI SHI",
              "code": 14
            },
            {
              "name": "CHONG ZHOU SHI",
              "code": 15
            },
            {
              "name": "JIN TANG XIAN",
              "code": 16
            },
            {
              "name": "SHUANG LIU XIAN",
              "code": 17
            },
            {
              "name": "PI XIAN",
              "code": 18
            },
            {
              "name": "DA YI XIAN",
              "code": 19
            },
            {
              "name": "PU JIANG XIAN",
              "code": 20
            },
            {
              "name": "XIN JIN XIAN",
              "code": 21
            },
            {
              "name": "DU JIANG YAN SHI",
              "code": 22
            },
            {
              "name": "PENG ZHOU SHI",
              "code": 23
            },
            {
              "name": "QIONG LAI SHI",
              "code": 24
            },
            {
              "name": "CHONG ZHOU SHI",
              "code": 25
            },
            {
              "name": "JIN TANG XIAN",
              "code": 26
            },
            {
              "name": "SHUANG LIU XIAN",
              "code": 27
            },
            {
              "name": "PI XIAN",
              "code": 28
            },
            {
              "name": "DA YI XIAN",
              "code": 29
            },
            {
              "name": "PU JIANG XIAN",
              "code": 30
            },
            {
              "name": "XIN JIN XIAN",
              "code": 31
            }
          ]
        },
        {
          "name": "MIAN YANG",
          "code": 2,
          "city": [
            {
              "name": "FU CHENG QU",
              "code": 1
            },
            {
              "name": "YOU XIAN QU",
              "code": 2
            },
            {
              "name": "JIANG YOU SHI",
              "code": 3
            },
            {
              "name": "YAN TING XIAN",
              "code": 4
            },
            {
              "name": "SAN TAI XIAN",
              "code": 5
            },
            {
              "name": "PING WU XIAN",
              "code": 6
            },
            {
              "name": "AN XIAN",
              "code": 7
            },
            {
              "name": "ZI TONG XIAN",
              "code": 8
            },
            {
              "name": "BEI CHUAN XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "A BA",
          "code": 3,
          "city": [
            {
              "name": "MA ER KANG XIAN",
              "code": 1
            },
            {
              "name": "WEN CHUAN XIAN",
              "code": 2
            },
            {
              "name": "LI XIAN",
              "code": 3
            },
            {
              "name": "MAO XIAN",
              "code": 4
            },
            {
              "name": "SONG PAN XIAN",
              "code": 5
            },
            {
              "name": "JIU ZHAI GOU XIAN",
              "code": 6
            },
            {
              "name": "JIN CHUAN XIAN",
              "code": 7
            },
            {
              "name": "XIAO JIN XIAN",
              "code": 8
            },
            {
              "name": "HEI SHUI XIAN",
              "code": 9
            },
            {
              "name": "RANG TANG XIAN",
              "code": 10
            },
            {
              "name": "A BA XIAN",
              "code": 11
            },
            {
              "name": "RUO ER GAI XIAN",
              "code": 12
            },
            {
              "name": "HONG YUAN XIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "BA ZHONG",
          "code": 4,
          "city": [
            {
              "name": "BA ZHOU QU",
              "code": 1
            },
            {
              "name": "TONG JIANG XIAN",
              "code": 2
            },
            {
              "name": "NAN JIANG XIAN",
              "code": 3
            },
            {
              "name": "PING CHANG XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "DA ZHOU",
          "code": 5,
          "city": [
            {
              "name": "TONG CHUAN QU",
              "code": 1
            },
            {
              "name": "WAN YUAN SHI",
              "code": 2
            },
            {
              "name": "DA XIAN",
              "code": 3
            },
            {
              "name": "XUAN HAN XIAN",
              "code": 4
            },
            {
              "name": "KAI JIANG XIAN",
              "code": 5
            },
            {
              "name": "DA ZHU XIAN",
              "code": 6
            },
            {
              "name": "QU XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "DE YANG",
          "code": 6,
          "city": [
            {
              "name": "JING YANG QU",
              "code": 1
            },
            {
              "name": "GUANG HAN SHI",
              "code": 2
            },
            {
              "name": "SHI FANG SHI",
              "code": 3
            },
            {
              "name": "MIAN ZHU SHI",
              "code": 4
            },
            {
              "name": "LUO JIANG XIAN",
              "code": 5
            },
            {
              "name": "ZHONG JIANG XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "GAN ZI",
          "code": 7,
          "city": [
            {
              "name": "KANG DING XIAN",
              "code": 1
            },
            {
              "name": "DAN BA XIAN",
              "code": 2
            },
            {
              "name": "LU DING XIAN",
              "code": 3
            },
            {
              "name": "LU HUO XIAN",
              "code": 4
            },
            {
              "name": "JIU LONG XIAN",
              "code": 5
            },
            {
              "name": "GAN ZI XIAN",
              "code": 6
            },
            {
              "name": "YA JIANG XIAN",
              "code": 7
            },
            {
              "name": "XIN LONG XIAN",
              "code": 8
            },
            {
              "name": "DAO FU XIAN",
              "code": 9
            },
            {
              "name": "BAI YU XIAN",
              "code": 10
            },
            {
              "name": "LI TANG XIAN",
              "code": 11
            },
            {
              "name": "DE GE XIAN",
              "code": 12
            },
            {
              "name": "XIANG CHENG XIAN",
              "code": 13
            },
            {
              "name": "SHI QU XIAN",
              "code": 14
            },
            {
              "name": "DAO CHENG XIAN",
              "code": 15
            },
            {
              "name": "SHAI DA XIAN",
              "code": 16
            },
            {
              "name": "BA TANG XIAN",
              "code": 17
            },
            {
              "name": "DE RONG XIAN",
              "code": 18
            }
          ]
        },
        {
          "name": "GUANG AN",
          "code": 8,
          "city": [
            {
              "name": "GUANG AN QU",
              "code": 1
            },
            {
              "name": "HUA YING SHI",
              "code": 2
            },
            {
              "name": "YUE CHI XIAN",
              "code": 3
            },
            {
              "name": "WU SHENG XIAN",
              "code": 4
            },
            {
              "name": "LIN SHUI XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "GUANG YUAN",
          "code": 9,
          "city": [
            {
              "name": "LI ZHOU QU",
              "code": 1
            },
            {
              "name": "YUAN BA QU",
              "code": 2
            },
            {
              "name": "CHAO TIAN QU",
              "code": 3
            },
            {
              "name": "WANG CANG XIAN",
              "code": 4
            },
            {
              "name": "QING CHUAN XIAN",
              "code": 5
            },
            {
              "name": "JIAN GE XIAN",
              "code": 6
            },
            {
              "name": "CANG XI XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "LE SHAN",
          "code": 10,
          "city": [
            {
              "name": "E MEI SHAN SHI",
              "code": 1
            },
            {
              "name": "LE SHAN SHI",
              "code": 2
            },
            {
              "name": "QIAN WEI XIAN",
              "code": 3
            },
            {
              "name": "JING YAN XIAN",
              "code": 4
            },
            {
              "name": "JIA JIANG XIAN",
              "code": 5
            },
            {
              "name": "MU CHUAN XIAN",
              "code": 6
            },
            {
              "name": "E BIAN",
              "code": 7
            },
            {
              "name": "MA BIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "LIANG SHAN",
          "code": 11,
          "city": [
            {
              "name": "XI CHANG SHI",
              "code": 1
            },
            {
              "name": "YAN YUAN XIAN",
              "code": 2
            },
            {
              "name": "DE CHANG XIAN",
              "code": 3
            },
            {
              "name": "HUI LI XIAN",
              "code": 4
            },
            {
              "name": "HUI DONG XIAN",
              "code": 5
            },
            {
              "name": "NING NAN XIAN",
              "code": 6
            },
            {
              "name": "PU GE XIAN",
              "code": 7
            },
            {
              "name": "BU TUO XIAN",
              "code": 8
            },
            {
              "name": "JIN YANG XIAN",
              "code": 9
            },
            {
              "name": "ZHAO JUE XIAN",
              "code": 10
            },
            {
              "name": "XI DE XIAN",
              "code": 11
            },
            {
              "name": "MIAN NING XIAN",
              "code": 12
            },
            {
              "name": "YUE XI XIAN",
              "code": 13
            },
            {
              "name": "GAN LUO XIAN",
              "code": 14
            },
            {
              "name": "MEI GU XIAN",
              "code": 15
            },
            {
              "name": "LEI BO XIAN",
              "code": 16
            },
            {
              "name": "MU LI",
              "code": 17
            }
          ]
        },
        {
          "name": "MEI SHAN",
          "code": 12,
          "city": [
            {
              "name": "DONG PO QU",
              "code": 1
            },
            {
              "name": "REN SHOU XIAN",
              "code": 2
            },
            {
              "name": "PENG SHAN XIAN",
              "code": 3
            },
            {
              "name": "HONG YA XIAN",
              "code": 4
            },
            {
              "name": "DAN LENG XIAN",
              "code": 5
            },
            {
              "name": "QING SHEN XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "NAN CHONG",
          "code": 13,
          "city": [
            {
              "name": "LANG ZHONG SHI",
              "code": 1
            },
            {
              "name": "NAN BU XIAN",
              "code": 2
            },
            {
              "name": "YING SHAN XIAN",
              "code": 3
            },
            {
              "name": "PENG AN XIAN",
              "code": 4
            },
            {
              "name": "YI LONG XIAN",
              "code": 5
            },
            {
              "name": "SHUN QING QU",
              "code": 6
            },
            {
              "name": "GAO PING QU",
              "code": 7
            },
            {
              "name": "JIA LING QU",
              "code": 8
            },
            {
              "name": "XI CHONG XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "NEI JIANG",
          "code": 14,
          "city": [
            {
              "name": "SHI ZHONG QU",
              "code": 1
            },
            {
              "name": "DONG XING QU",
              "code": 2
            },
            {
              "name": "WEI YUAN XIAN",
              "code": 3
            },
            {
              "name": "ZI ZHONG XIAN",
              "code": 4
            },
            {
              "name": "LONG CHANG XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "PAN ZHI HUA",
          "code": 15,
          "city": [
            {
              "name": "DONG QU",
              "code": 1
            },
            {
              "name": "XI QU",
              "code": 2
            },
            {
              "name": "REN HE QU",
              "code": 3
            },
            {
              "name": "MI YI XIAN",
              "code": 4
            },
            {
              "name": "YAN BIAN XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "SUI NING",
          "code": 16,
          "city": [
            {
              "name": "CHUAN SHAN QU",
              "code": 1
            },
            {
              "name": "AN JU QU",
              "code": 2
            },
            {
              "name": "PENG XI XIAN",
              "code": 3
            },
            {
              "name": "SHE HONG XIAN",
              "code": 4
            },
            {
              "name": "DA YING XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "YA AN",
          "code": 17,
          "city": [
            {
              "name": "YU CHENG QU",
              "code": 1
            },
            {
              "name": "MING SHAN XIAN",
              "code": 2
            },
            {
              "name": "YING JING XIAN",
              "code": 3
            },
            {
              "name": "HAN YUAN XIAN",
              "code": 4
            },
            {
              "name": "SHI MIAN XIAN",
              "code": 5
            },
            {
              "name": "TIAN QUAN XIAN",
              "code": 6
            },
            {
              "name": "LU SHAN XIAN",
              "code": 7
            },
            {
              "name": "BAO XING XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "YI BIN",
          "code": 18,
          "city": [
            {
              "name": "CUI PING QU",
              "code": 1
            },
            {
              "name": "YI BIN XIAN",
              "code": 2
            },
            {
              "name": "NAN XI XIAN",
              "code": 3
            },
            {
              "name": "JIANG AN XIAN",
              "code": 4
            },
            {
              "name": "CHANG NING XIAN",
              "code": 5
            },
            {
              "name": "GAO XIAN",
              "code": 6
            },
            {
              "name": "GONG XIAN",
              "code": 7
            },
            {
              "name": "JUN LIAN XIAN",
              "code": 8
            },
            {
              "name": "XING WEN XIAN",
              "code": 9
            },
            {
              "name": "PING SHAN XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "ZI YANG",
          "code": 19,
          "city": [
            {
              "name": "YAN JIANG QU",
              "code": 1
            },
            {
              "name": "JIAN YANG SHI",
              "code": 2
            },
            {
              "name": "AN YUE XIAN",
              "code": 3
            },
            {
              "name": "LE ZHI XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "ZI GONG",
          "code": 20,
          "city": [
            {
              "name": "DA AN QU",
              "code": 1
            },
            {
              "name": "ZI LIU JING QU",
              "code": 2
            },
            {
              "name": "GONG JING QU",
              "code": 3
            },
            {
              "name": "YAN TAN QU",
              "code": 4
            },
            {
              "name": "RONG XIAN",
              "code": 5
            },
            {
              "name": "FU SHUN XIAN",
              "code": 6
            }
          ]
        },
        {
          "name": "LU ZHOU",
          "code": 21,
          "city": [
            {
              "name": "JIANG YANG QU",
              "code": 1
            },
            {
              "name": "NA XI QU",
              "code": 2
            },
            {
              "name": "LONG MA TAN QU",
              "code": 3
            },
            {
              "name": "LU XIAN",
              "code": 4
            },
            {
              "name": "HE JIANG XIAN",
              "code": 5
            },
            {
              "name": "XU YONG XIAN",
              "code": 6
            },
            {
              "name": "GU LIN XIAN",
              "code": 7
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "TIAN JIN",
      "code": 26,
      "state": [
        {
          "name": "TIAN JIN",
          "code": 1,
          "city": [
            {
              "name": "HE PING QU",
              "code": 1
            },
            {
              "name": "HE XI QU",
              "code": 2
            },
            {
              "name": "NAN KAI QU",
              "code": 3
            },
            {
              "name": "HE BEI QU",
              "code": 4
            },
            {
              "name": "HE DONG QU",
              "code": 5
            },
            {
              "name": "HONG QIAO QU",
              "code": 6
            },
            {
              "name": "DONG LI QU",
              "code": 7
            },
            {
              "name": "JIN NAN QU",
              "code": 8
            },
            {
              "name": "XI QING QU",
              "code": 9
            },
            {
              "name": "BEI CHEN QU",
              "code": 10
            },
            {
              "name": "TANG GU QU",
              "code": 11
            },
            {
              "name": "HAN GU QU",
              "code": 12
            },
            {
              "name": "DA GANG QU",
              "code": 13
            },
            {
              "name": "WU QING QU",
              "code": 14
            },
            {
              "name": "BAO DI QU",
              "code": 15
            },
            {
              "name": "JING JI KAI FA QU",
              "code": 16
            },
            {
              "name": "NING HE XIAN",
              "code": 17
            },
            {
              "name": "JING HAI XIAN",
              "code": 18
            },
            {
              "name": "JI XIAN",
              "code": 19
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "XI ZANG",
      "code": 27,
      "state": [
        {
          "name": "LA SA",
          "code": 1,
          "city": [
            {
              "name": "CHENG GUAN QU",
              "code": 1
            },
            {
              "name": "LIN ZHOU XIAN",
              "code": 2
            },
            {
              "name": "DANG XIONG XIAN",
              "code": 3
            },
            {
              "name": "NI MU XIAN",
              "code": 4
            },
            {
              "name": "QU SHUI XIAN",
              "code": 5
            },
            {
              "name": "DUI LONG DE QING XIAN",
              "code": 6
            },
            {
              "name": "DA ZI XIAN",
              "code": 7
            },
            {
              "name": "MO ZHU GONG KA XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "A LI",
          "code": 2,
          "city": [
            {
              "name": "GA ER XIAN",
              "code": 1
            },
            {
              "name": "PU LAN XIAN",
              "code": 2
            },
            {
              "name": "ZHA DA XIAN",
              "code": 3
            },
            {
              "name": "RI TU XIAN",
              "code": 4
            },
            {
              "name": "GE JI XIAN",
              "code": 5
            },
            {
              "name": "GAI ZE XIAN",
              "code": 6
            },
            {
              "name": "CUO QIN XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "CHANG DU",
          "code": 3,
          "city": [
            {
              "name": "CHANG DU XIAN",
              "code": 1
            },
            {
              "name": "JIANG DA XIAN",
              "code": 2
            },
            {
              "name": "GONG JUE XIAN",
              "code": 3
            },
            {
              "name": "LEI WU QI XIAN",
              "code": 4
            },
            {
              "name": "DING QING XIAN",
              "code": 5
            },
            {
              "name": "CHA YA XIAN",
              "code": 6
            },
            {
              "name": "BA SU XIAN",
              "code": 7
            },
            {
              "name": "ZUO GONG XIAN",
              "code": 8
            },
            {
              "name": "MANG KANG XIAN",
              "code": 9
            },
            {
              "name": "LUO LONG XIAN",
              "code": 10
            },
            {
              "name": "BIAN BA XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "LIN ZHI",
          "code": 4,
          "city": [
            {
              "name": "LIN ZHI XIAN",
              "code": 1
            },
            {
              "name": "GONG BU JIANG DA XIAN",
              "code": 2
            },
            {
              "name": "MI LIN XIAN",
              "code": 3
            },
            {
              "name": "MO TUO XIAN",
              "code": 4
            },
            {
              "name": "BO MI XIAN",
              "code": 5
            },
            {
              "name": "CHA YU XIAN",
              "code": 6
            },
            {
              "name": "LANG XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "NA QU",
          "code": 5,
          "city": [
            {
              "name": "NA QU XIAN",
              "code": 1
            },
            {
              "name": "JIA LI XIAN",
              "code": 2
            },
            {
              "name": "BI RU XIAN",
              "code": 3
            },
            {
              "name": "NIE RONG XIAN",
              "code": 4
            },
            {
              "name": "AN DUO XIAN",
              "code": 5
            },
            {
              "name": "SHEN ZHA XIAN",
              "code": 6
            },
            {
              "name": "SUO XIAN",
              "code": 7
            },
            {
              "name": "BAN GE XIAN",
              "code": 8
            },
            {
              "name": "BA QING XIAN",
              "code": 9
            },
            {
              "name": "NI MA XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "RI KA ZE",
          "code": 6,
          "city": [
            {
              "name": "RI KA ZE SHI",
              "code": 1
            },
            {
              "name": "NAN MU LIN XIAN",
              "code": 2
            },
            {
              "name": "JIANG ZI XIAN",
              "code": 3
            },
            {
              "name": "DING RI XIAN",
              "code": 4
            },
            {
              "name": "SA JIA XIAN",
              "code": 5
            },
            {
              "name": "LA ZI XIAN",
              "code": 6
            },
            {
              "name": "ANG REN XIAN",
              "code": 7
            },
            {
              "name": "XIE TONG MEN XIAN",
              "code": 8
            },
            {
              "name": "BAI LANG XIAN",
              "code": 9
            },
            {
              "name": "REN BU XIAN",
              "code": 10
            },
            {
              "name": "KANG MA XIAN",
              "code": 11
            },
            {
              "name": "DING JIE XIAN",
              "code": 12
            },
            {
              "name": "ZHONG BA XIAN",
              "code": 13
            },
            {
              "name": "YA DONG XIAN",
              "code": 14
            },
            {
              "name": "JI LONG XIAN",
              "code": 15
            },
            {
              "name": "NIE LA MU XIAN",
              "code": 16
            },
            {
              "name": "SA GA XIAN",
              "code": 17
            },
            {
              "name": "GANG BA XIAN",
              "code": 18
            }
          ]
        },
        {
          "name": "SHAN NAN",
          "code": 7,
          "city": [
            {
              "name": "NAI DONG XIAN",
              "code": 1
            },
            {
              "name": "ZA NANG XIAN",
              "code": 2
            },
            {
              "name": "GONG GA XIAN",
              "code": 3
            },
            {
              "name": "SANG RI XIAN",
              "code": 4
            },
            {
              "name": "QIONG JIE XIAN",
              "code": 5
            },
            {
              "name": "QU SONG XIAN",
              "code": 6
            },
            {
              "name": "CUO MEI XIAN",
              "code": 7
            },
            {
              "name": "LUO ZHA XIAN",
              "code": 8
            },
            {
              "name": "JIA CHA XIAN",
              "code": 9
            },
            {
              "name": "LONG ZI XIAN",
              "code": 10
            },
            {
              "name": "CUO NA XIAN",
              "code": 11
            },
            {
              "name": "LANG KA ZI XIAN",
              "code": 12
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "XIN JIANG",
      "code": 28,
      "state": [
        {
          "name": "WU LU MU QI",
          "code": 1,
          "city": [
            {
              "name": "TIAN SHAN QU",
              "code": 1
            },
            {
              "name": "SHA YI BA KE QU",
              "code": 2
            },
            {
              "name": "XIN SHI QU",
              "code": 3
            },
            {
              "name": "SHUI MO GOU QU",
              "code": 4
            },
            {
              "name": "TOU TUN HE QU",
              "code": 5
            },
            {
              "name": "DA BAN CHENG QU",
              "code": 6
            },
            {
              "name": "MI DONG QU",
              "code": 7
            },
            {
              "name": "WU LU MU QI XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "A KE SU",
          "code": 2,
          "city": [
            {
              "name": "A KE SU SHI",
              "code": 1
            },
            {
              "name": "WEN SU XIAN",
              "code": 2
            },
            {
              "name": "KU CHE XIAN",
              "code": 3
            },
            {
              "name": "SHA YA XIAN",
              "code": 4
            },
            {
              "name": "XIN HE XIAN",
              "code": 5
            },
            {
              "name": "BAI CHENG XIAN",
              "code": 6
            },
            {
              "name": "WU SHI XIAN",
              "code": 7
            },
            {
              "name": "A WA TI XIAN",
              "code": 8
            },
            {
              "name": "KE PING XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "A LA ER",
          "code": 3,
          "city": [
            {
              "name": "A LA ER SHI",
              "code": 1
            }
          ]
        },
        {
          "name": "BA YIN GUO LENG",
          "code": 4,
          "city": [
            {
              "name": "KU ER LE SHI",
              "code": 1
            },
            {
              "name": "LUN TAI XIAN",
              "code": 2
            },
            {
              "name": "YU LI XIAN",
              "code": 3
            },
            {
              "name": "RUO QIANG XIAN",
              "code": 4
            },
            {
              "name": "QIE MO XIAN",
              "code": 5
            },
            {
              "name": "YAN QI",
              "code": 6
            },
            {
              "name": "HE JING XIAN",
              "code": 7
            },
            {
              "name": "HE SHUO XIAN",
              "code": 8
            },
            {
              "name": "BO HU XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "BO ER TA LA",
          "code": 5,
          "city": [
            {
              "name": "BO LE SHI",
              "code": 1
            },
            {
              "name": "JING HE XIAN",
              "code": 2
            },
            {
              "name": "WEN QUAN XIAN",
              "code": 3
            }
          ]
        },
        {
          "name": "CHANG JI",
          "code": 6,
          "city": [
            {
              "name": "HU TU BI XIAN",
              "code": 1
            },
            {
              "name": "MI QUAN SHI",
              "code": 2
            },
            {
              "name": "CHANG JI SHI",
              "code": 3
            },
            {
              "name": "FU KANG SHI",
              "code": 4
            },
            {
              "name": "MA NA SI XIAN",
              "code": 5
            },
            {
              "name": "QI TAI XIAN",
              "code": 6
            },
            {
              "name": "JI MU SA ER XIAN",
              "code": 7
            },
            {
              "name": "MU LEI",
              "code": 8
            }
          ]
        },
        {
          "name": "HA MI",
          "code": 7,
          "city": [
            {
              "name": "HA MI SHI",
              "code": 1
            },
            {
              "name": "YI WU XIAN",
              "code": 2
            },
            {
              "name": "BA LI KUN",
              "code": 3
            }
          ]
        },
        {
          "name": "HE TIAN",
          "code": 8,
          "city": [
            {
              "name": "HE TIAN SHI",
              "code": 1
            },
            {
              "name": "HE TIAN XIAN",
              "code": 2
            },
            {
              "name": "MO YU XIAN",
              "code": 3
            },
            {
              "name": "PI SHAN XIAN",
              "code": 4
            },
            {
              "name": "LUO PU XIAN",
              "code": 5
            },
            {
              "name": "CE LE XIAN",
              "code": 6
            },
            {
              "name": "YU TIAN XIAN",
              "code": 7
            },
            {
              "name": "MIN FENG XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "KA SHI",
          "code": 9,
          "city": [
            {
              "name": "KA SHI SHI",
              "code": 1
            },
            {
              "name": "SHU FU XIAN",
              "code": 2
            },
            {
              "name": "SHU LE XIAN",
              "code": 3
            },
            {
              "name": "YING JI SHA XIAN",
              "code": 4
            },
            {
              "name": "ZE PU XIAN",
              "code": 5
            },
            {
              "name": "SHA CHE XIAN",
              "code": 6
            },
            {
              "name": "YE CHENG XIAN",
              "code": 7
            },
            {
              "name": "MAI GE TI XIAN",
              "code": 8
            },
            {
              "name": "YUE PU HU XIAN",
              "code": 9
            },
            {
              "name": "JIA SHI XIAN",
              "code": 10
            },
            {
              "name": "BA CHU XIAN",
              "code": 11
            },
            {
              "name": "TA SHI KU ER GAN",
              "code": 12
            }
          ]
        },
        {
          "name": "KE LA MA YI",
          "code": 10,
          "city": [
            {
              "name": "KE LA MA YI SHI",
              "code": 1
            }
          ]
        },
        {
          "name": "KE ZI LE SU",
          "code": 11,
          "city": [
            {
              "name": "A TU SHI SHI",
              "code": 1
            },
            {
              "name": "A KE TAO XIAN",
              "code": 2
            },
            {
              "name": "A HE QI XIAN",
              "code": 3
            },
            {
              "name": "WU QIA XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "SHI HE ZI",
          "code": 12,
          "city": [
            {
              "name": "SHI HE ZI SHI",
              "code": 1
            }
          ]
        },
        {
          "name": "TU MU SHU KE",
          "code": 13,
          "city": [
            {
              "name": "TU MU SHU KE SHI",
              "code": 1
            }
          ]
        },
        {
          "name": "TU LU FAN",
          "code": 14,
          "city": [
            {
              "name": "TU LU FAN SHI",
              "code": 1
            },
            {
              "name": "SHAN SHAN XIAN",
              "code": 2
            },
            {
              "name": "TUO KE XUN XIAN",
              "code": 3
            }
          ]
        },
        {
          "name": "WU JIA QU",
          "code": 15,
          "city": [
            {
              "name": "WU JIA QU SHI",
              "code": 1
            }
          ]
        },
        {
          "name": "YI LI",
          "code": 16,
          "city": [
            {
              "name": "A LE TAI SHI",
              "code": 1
            },
            {
              "name": "BU KE SAI ER",
              "code": 2
            },
            {
              "name": "YI NING SHI",
              "code": 3
            },
            {
              "name": "BU ER JIN XIAN",
              "code": 4
            },
            {
              "name": "KUI TUN SHI",
              "code": 5
            },
            {
              "name": "WU SU SHI",
              "code": 6
            },
            {
              "name": "E MIN XIAN",
              "code": 7
            },
            {
              "name": "FU YUN XIAN",
              "code": 8
            },
            {
              "name": "YI NING XIAN",
              "code": 9
            },
            {
              "name": "FU HAI XIAN",
              "code": 10
            },
            {
              "name": "HUO CHENG XIAN",
              "code": 11
            },
            {
              "name": "SHA WAN XIAN",
              "code": 12
            },
            {
              "name": "GONG LIU XIAN",
              "code": 13
            },
            {
              "name": "HA BA HE XIAN",
              "code": 14
            },
            {
              "name": "TUO LI XIAN",
              "code": 15
            },
            {
              "name": "QING HE XIAN",
              "code": 16
            },
            {
              "name": "XIN YUAN XIAN",
              "code": 17
            },
            {
              "name": "YU MIN XIAN",
              "code": 18
            },
            {
              "name": "HE BU KE SAI ER",
              "code": 19
            },
            {
              "name": "JI MU NAI XIAN",
              "code": 20
            },
            {
              "name": "ZHAO SU XIAN",
              "code": 21
            },
            {
              "name": "TE KE SI XIAN",
              "code": 22
            },
            {
              "name": "NI LE KE XIAN",
              "code": 23
            },
            {
              "name": "CHA BU CHA ER",
              "code": 24
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "YUN NAN",
      "code": 29,
      "state": [
        {
          "name": "KUN MING",
          "code": 1,
          "city": [
            {
              "name": "PAN LONG QU",
              "code": 1
            },
            {
              "name": "WU HUA QU",
              "code": 2
            },
            {
              "name": "GUAN DU QU",
              "code": 3
            },
            {
              "name": "XI SHAN QU",
              "code": 4
            },
            {
              "name": "DONG CHUAN QU",
              "code": 5
            },
            {
              "name": "AN NING SHI",
              "code": 6
            },
            {
              "name": "CHENG GONG XIAN",
              "code": 7
            },
            {
              "name": "JIN NING XIAN",
              "code": 8
            },
            {
              "name": "FU MIN XIAN",
              "code": 9
            },
            {
              "name": "YI LIANG XIAN",
              "code": 10
            },
            {
              "name": "SONG MING XIAN",
              "code": 11
            },
            {
              "name": "SHI LIN XIAN",
              "code": 12
            },
            {
              "name": "LU QUAN",
              "code": 13
            },
            {
              "name": "XUN DIAN",
              "code": 14
            }
          ]
        },
        {
          "name": "NU JIANG",
          "code": 2,
          "city": [
            {
              "name": "LAN PING",
              "code": 1
            },
            {
              "name": "LU SHUI XIAN",
              "code": 2
            },
            {
              "name": "FU GONG XIAN",
              "code": 3
            },
            {
              "name": "GONG SHAN",
              "code": 4
            }
          ]
        },
        {
          "name": "PU ER",
          "code": 3,
          "city": [
            {
              "name": "NING ER",
              "code": 1
            },
            {
              "name": "SI MAO QU",
              "code": 2
            },
            {
              "name": "MO JIANG",
              "code": 3
            },
            {
              "name": "JING DONG",
              "code": 4
            },
            {
              "name": "JING GU",
              "code": 5
            },
            {
              "name": "ZHEN YUAN",
              "code": 6
            },
            {
              "name": "JIANG CHENG",
              "code": 7
            },
            {
              "name": "MENG LIAN",
              "code": 8
            },
            {
              "name": "LAN CANG",
              "code": 9
            },
            {
              "name": "XI MENG",
              "code": 10
            }
          ]
        },
        {
          "name": "LI JIANG",
          "code": 4,
          "city": [
            {
              "name": "GU CHENG QU",
              "code": 1
            },
            {
              "name": "NING LANG",
              "code": 2
            },
            {
              "name": "YU LONG",
              "code": 3
            },
            {
              "name": "YONG SHENG XIAN",
              "code": 4
            },
            {
              "name": "HUA PING XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "BAO SHAN",
          "code": 5,
          "city": [
            {
              "name": "LONG YANG QU",
              "code": 1
            },
            {
              "name": "SHI DIAN XIAN",
              "code": 2
            },
            {
              "name": "TENG CHONG XIAN",
              "code": 3
            },
            {
              "name": "LONG LING XIAN",
              "code": 4
            },
            {
              "name": "CHANG NING XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "CHU XIONG",
          "code": 6,
          "city": [
            {
              "name": "CHU XIONG SHI",
              "code": 1
            },
            {
              "name": "SHUANG BAI XIAN",
              "code": 2
            },
            {
              "name": "MOU DING XIAN",
              "code": 3
            },
            {
              "name": "NAN HUA XIAN",
              "code": 4
            },
            {
              "name": "YAO AN XIAN",
              "code": 5
            },
            {
              "name": "DA YAO XIAN",
              "code": 6
            },
            {
              "name": "YONG REN XIAN",
              "code": 7
            },
            {
              "name": "YUAN MOU XIAN",
              "code": 8
            },
            {
              "name": "WU DING XIAN",
              "code": 9
            },
            {
              "name": "LU FENG XIAN",
              "code": 10
            }
          ]
        },
        {
          "name": "DA LI",
          "code": 7,
          "city": [
            {
              "name": "DA LI SHI",
              "code": 1
            },
            {
              "name": "XIANG YUN XIAN",
              "code": 2
            },
            {
              "name": "BIN CHUAN XIAN",
              "code": 3
            },
            {
              "name": "MI DU XIAN",
              "code": 4
            },
            {
              "name": "YONG PING XIAN",
              "code": 5
            },
            {
              "name": "YUN LONG XIAN",
              "code": 6
            },
            {
              "name": "ER YUAN XIAN",
              "code": 7
            },
            {
              "name": "JIAN CHUAN XIAN",
              "code": 8
            },
            {
              "name": "HE QING XIAN",
              "code": 9
            },
            {
              "name": "YANG BI",
              "code": 10
            },
            {
              "name": "NAN JIAN",
              "code": 11
            },
            {
              "name": "WEI SHAN",
              "code": 12
            }
          ]
        },
        {
          "name": "DE HONG",
          "code": 8,
          "city": [
            {
              "name": "LU XI SHI",
              "code": 1
            },
            {
              "name": "RUI LI SHI",
              "code": 2
            },
            {
              "name": "LIANG HE XIAN",
              "code": 3
            },
            {
              "name": "YING JIANG XIAN",
              "code": 4
            },
            {
              "name": "LONG CHUAN XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "DI QING",
          "code": 9,
          "city": [
            {
              "name": "XIANG GE LI LA XIAN",
              "code": 1
            },
            {
              "name": "DE QIN XIAN",
              "code": 2
            },
            {
              "name": "WEI XI",
              "code": 3
            }
          ]
        },
        {
          "name": "HONG HE",
          "code": 10,
          "city": [
            {
              "name": "LU XI XIAN",
              "code": 1
            },
            {
              "name": "MENG ZI XIAN",
              "code": 2
            },
            {
              "name": "GE JIU SHI",
              "code": 3
            },
            {
              "name": "KAI YUAN SHI",
              "code": 4
            },
            {
              "name": "LYU CHUN XIAN",
              "code": 5
            },
            {
              "name": "JIAN SHUI XIAN",
              "code": 6
            },
            {
              "name": "SHI PING XIAN",
              "code": 7
            },
            {
              "name": "MI LE XIAN",
              "code": 8
            },
            {
              "name": "YUAN YANG XIAN",
              "code": 9
            },
            {
              "name": "HONG HE XIAN",
              "code": 10
            },
            {
              "name": "JIN PING",
              "code": 11
            },
            {
              "name": "HE KOU",
              "code": 12
            },
            {
              "name": "PING BIAN",
              "code": 13
            }
          ]
        },
        {
          "name": "LIN CANG",
          "code": 11,
          "city": [
            {
              "name": "LIN XIANG QU",
              "code": 1
            },
            {
              "name": "FENG QING XIAN",
              "code": 2
            },
            {
              "name": "YUN XIAN",
              "code": 3
            },
            {
              "name": "YONG DE XIAN",
              "code": 4
            },
            {
              "name": "ZHEN KANG XIAN",
              "code": 5
            },
            {
              "name": "SHUANG JIANG",
              "code": 6
            },
            {
              "name": "GENG MA",
              "code": 7
            },
            {
              "name": "CANG YUAN",
              "code": 8
            }
          ]
        },
        {
          "name": "QU JING",
          "code": 12,
          "city": [
            {
              "name": "QI LIN QU",
              "code": 1
            },
            {
              "name": "XUAN WEI SHI",
              "code": 2
            },
            {
              "name": "MA LONG XIAN",
              "code": 3
            },
            {
              "name": "LU LIANG XIAN",
              "code": 4
            },
            {
              "name": "SHI ZONG XIAN",
              "code": 5
            },
            {
              "name": "LUO PING XIAN",
              "code": 6
            },
            {
              "name": "FU YUAN XIAN",
              "code": 7
            },
            {
              "name": "HUI ZE XIAN",
              "code": 8
            },
            {
              "name": "ZHAN YI XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "WEN SHAN",
          "code": 13,
          "city": [
            {
              "name": "WEN SHAN XIAN",
              "code": 1
            },
            {
              "name": "YAN SHAN XIAN",
              "code": 2
            },
            {
              "name": "XI CHOU XIAN",
              "code": 3
            },
            {
              "name": "MA LI PO XIAN",
              "code": 4
            },
            {
              "name": "MA GUAN XIAN",
              "code": 5
            },
            {
              "name": "QIU BEI XIAN",
              "code": 6
            },
            {
              "name": "GUANG NAN XIAN",
              "code": 7
            },
            {
              "name": "FU NING XIAN",
              "code": 8
            }
          ]
        },
        {
          "name": "XI SHUANG BAN NA",
          "code": 14,
          "city": [
            {
              "name": "JING HONG SHI",
              "code": 1
            },
            {
              "name": "MENG HAI XIAN",
              "code": 2
            },
            {
              "name": "MENG LA XIAN",
              "code": 3
            }
          ]
        },
        {
          "name": "YU XI",
          "code": 15,
          "city": [
            {
              "name": "HONG TA QU",
              "code": 1
            },
            {
              "name": "JIANG CHUAN XIAN",
              "code": 2
            },
            {
              "name": "CHENG JIANG XIAN",
              "code": 3
            },
            {
              "name": "TONG HAI XIAN",
              "code": 4
            },
            {
              "name": "HUA NING XIAN",
              "code": 5
            },
            {
              "name": "YI MEN XIAN",
              "code": 6
            },
            {
              "name": "E SHAN",
              "code": 7
            },
            {
              "name": "XIN PING",
              "code": 8
            },
            {
              "name": "YUAN JIANG",
              "code": 9
            }
          ]
        },
        {
          "name": "ZHAO TONG",
          "code": 16,
          "city": [
            {
              "name": "ZHAO YANG QU",
              "code": 1
            },
            {
              "name": "LU DIAN XIAN",
              "code": 2
            },
            {
              "name": "QIAO JIA XIAN",
              "code": 3
            },
            {
              "name": "YAN JIN XIAN",
              "code": 4
            },
            {
              "name": "DA GUAN XIAN",
              "code": 5
            },
            {
              "name": "YONG SHAN XIAN",
              "code": 6
            },
            {
              "name": "SUI JIANG XIAN",
              "code": 7
            },
            {
              "name": "ZHEN XIONG XIAN",
              "code": 8
            },
            {
              "name": "YI LIANG XIAN",
              "code": 9
            },
            {
              "name": "WEI XIN XIAN",
              "code": 10
            },
            {
              "name": "SHUI FU XIAN",
              "code": 11
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "ZHE JIANG",
      "code": 30,
      "state": [
        {
          "name": "HANG ZHOU",
          "code": 1,
          "city": [
            {
              "name": "XI HU QU",
              "code": 1
            },
            {
              "name": "SHANG CHENG QU",
              "code": 2
            },
            {
              "name": "XIA CHENG QU",
              "code": 3
            },
            {
              "name": "GONG SHU QU",
              "code": 4
            },
            {
              "name": "BIN JIANG QU",
              "code": 5
            },
            {
              "name": "JIANG GAN QU",
              "code": 6
            },
            {
              "name": "XIAO SHAN QU",
              "code": 7
            },
            {
              "name": "YU HANG QU",
              "code": 8
            },
            {
              "name": "SHI JIAO",
              "code": 9
            },
            {
              "name": "JIAN DE SHI",
              "code": 10
            },
            {
              "name": "FU YANG SHI",
              "code": 11
            },
            {
              "name": "LIN AN SHI",
              "code": 12
            },
            {
              "name": "TONG LU XIAN",
              "code": 13
            },
            {
              "name": "CHUN AN XIAN",
              "code": 14
            }
          ]
        },
        {
          "name": "HU ZHOU",
          "code": 2,
          "city": [
            {
              "name": "WU XING QU",
              "code": 1
            },
            {
              "name": "NAN XUN QU",
              "code": 2
            },
            {
              "name": "DE QING XIAN",
              "code": 3
            },
            {
              "name": "CHANG XING XIAN",
              "code": 4
            },
            {
              "name": "AN JI XIAN",
              "code": 5
            }
          ]
        },
        {
          "name": "JIA XING",
          "code": 3,
          "city": [
            {
              "name": "NAN HU QU",
              "code": 1
            },
            {
              "name": "XIU ZHOU QU",
              "code": 2
            },
            {
              "name": "HAI NING SHI",
              "code": 3
            },
            {
              "name": "JIA SHAN XIAN",
              "code": 4
            },
            {
              "name": "PING HU SHI",
              "code": 5
            },
            {
              "name": "TONG XIANG SHI",
              "code": 6
            },
            {
              "name": "HAI YAN XIAN",
              "code": 7
            }
          ]
        },
        {
          "name": "JIN HUA",
          "code": 4,
          "city": [
            {
              "name": "WU CHENG QU",
              "code": 1
            },
            {
              "name": "JIN DONG QU",
              "code": 2
            },
            {
              "name": "LAN XI SHI",
              "code": 3
            },
            {
              "name": "SHI QU",
              "code": 4
            },
            {
              "name": "FO TANG ZHEN",
              "code": 5
            },
            {
              "name": "SHANG XI ZHEN",
              "code": 6
            },
            {
              "name": "YI TING ZHEN",
              "code": 7
            },
            {
              "name": "DA CHEN ZHEN",
              "code": 8
            },
            {
              "name": "SU XI ZHEN",
              "code": 9
            },
            {
              "name": "CHI AN ZHEN",
              "code": 10
            },
            {
              "name": "DONG YANG SHI",
              "code": 11
            },
            {
              "name": "YONG KANG SHI",
              "code": 12
            },
            {
              "name": "WU YI XIAN",
              "code": 13
            },
            {
              "name": "PU JIANG XIAN",
              "code": 14
            },
            {
              "name": "PAN AN XIAN",
              "code": 15
            }
          ]
        },
        {
          "name": "LI SHUI",
          "code": 5,
          "city": [
            {
              "name": "LIAN DU QU",
              "code": 1
            },
            {
              "name": "LONG QUAN SHI",
              "code": 2
            },
            {
              "name": "QING TIAN XIAN",
              "code": 3
            },
            {
              "name": "JIN YUN XIAN",
              "code": 4
            },
            {
              "name": "SUI CHANG XIAN",
              "code": 5
            },
            {
              "name": "SONG YANG XIAN",
              "code": 6
            },
            {
              "name": "YUN HE XIAN",
              "code": 7
            },
            {
              "name": "QING YUAN XIAN",
              "code": 8
            },
            {
              "name": "JING NING",
              "code": 9
            }
          ]
        },
        {
          "name": "NING BO",
          "code": 6,
          "city": [
            {
              "name": "HAI SHU QU",
              "code": 1
            },
            {
              "name": "JIANG DONG QU",
              "code": 2
            },
            {
              "name": "JIANG BEI QU",
              "code": 3
            },
            {
              "name": "ZHEN HAI QU",
              "code": 4
            },
            {
              "name": "BEI LUN QU",
              "code": 5
            },
            {
              "name": "YIN ZHOU QU",
              "code": 6
            },
            {
              "name": "YU YAO SHI",
              "code": 7
            },
            {
              "name": "CI XI SHI",
              "code": 8
            },
            {
              "name": "FENG HUA SHI",
              "code": 9
            },
            {
              "name": "XIANG SHAN XIAN",
              "code": 10
            },
            {
              "name": "NING HAI XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "SHAO XING",
          "code": 7,
          "city": [
            {
              "name": "YUE CHENG QU",
              "code": 1
            },
            {
              "name": "SHANG YU SHI",
              "code": 2
            },
            {
              "name": "SHENG ZHOU SHI",
              "code": 3
            },
            {
              "name": "SHAO XING XIAN",
              "code": 4
            },
            {
              "name": "XIN CHANG XIAN",
              "code": 5
            },
            {
              "name": "ZHU JI SHI",
              "code": 6
            }
          ]
        },
        {
          "name": "TAI ZHOU",
          "code": 8,
          "city": [
            {
              "name": "JIAO JIANG QU",
              "code": 1
            },
            {
              "name": "HUANG YAN QU",
              "code": 2
            },
            {
              "name": "LU QIAO QU",
              "code": 3
            },
            {
              "name": "WEN LING SHI",
              "code": 4
            },
            {
              "name": "LIN HAI SHI",
              "code": 5
            },
            {
              "name": "YU HUAN XIAN",
              "code": 6
            },
            {
              "name": "SAN MEN XIAN",
              "code": 7
            },
            {
              "name": "TIAN TAI XIAN",
              "code": 8
            },
            {
              "name": "XIAN JU XIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "WEN ZHOU",
          "code": 9,
          "city": [
            {
              "name": "LU CHENG QU",
              "code": 1
            },
            {
              "name": "LONG WAN QU",
              "code": 2
            },
            {
              "name": "OU HAI QU",
              "code": 3
            },
            {
              "name": "RUI AN SHI",
              "code": 4
            },
            {
              "name": "YUE QING SHI",
              "code": 5
            },
            {
              "name": "DONG TOU XIAN",
              "code": 6
            },
            {
              "name": "YONG JIA XIAN",
              "code": 7
            },
            {
              "name": "PING YANG XIAN",
              "code": 8
            },
            {
              "name": "CANG NAN XIAN",
              "code": 9
            },
            {
              "name": "WEN CHENG XIAN",
              "code": 10
            },
            {
              "name": "TAI SHUN XIAN",
              "code": 11
            }
          ]
        },
        {
          "name": "ZHOU SHAN",
          "code": 10,
          "city": [
            {
              "name": "DING HAI QU",
              "code": 1
            },
            {
              "name": "PU TUO QU",
              "code": 2
            },
            {
              "name": "DAI SHAN XIAN",
              "code": 3
            },
            {
              "name": "SHENG SI XIAN",
              "code": 4
            }
          ]
        },
        {
          "name": "QU ZHOU",
          "code": 11,
          "city": [
            {
              "name": "QU ZHOU SHI",
              "code": 1
            },
            {
              "name": "JIANG SHAN SHI",
              "code": 2
            },
            {
              "name": "CHANG SHAN XIAN",
              "code": 3
            },
            {
              "name": "KAI HUA XIAN",
              "code": 4
            },
            {
              "name": "LONG YOU XIAN",
              "code": 5
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "CHONG QING",
      "code": 31,
      "state": [
        {
          "name": "CHONG QING",
          "code": 1,
          "city": [
            {
              "name": "HE CHUAN QU",
              "code": 1
            },
            {
              "name": "JIANG JIN QU",
              "code": 2
            },
            {
              "name": "NAN CHUAN QU",
              "code": 3
            },
            {
              "name": "YONG CHUAN QU",
              "code": 4
            },
            {
              "name": "NAN AN QU",
              "code": 5
            },
            {
              "name": "YU BEI QU",
              "code": 6
            },
            {
              "name": "WAN SHENG QU",
              "code": 7
            },
            {
              "name": "DA DU KOU QU",
              "code": 8
            },
            {
              "name": "WAN ZHOU QU",
              "code": 9
            },
            {
              "name": "BEI BEI QU",
              "code": 10
            },
            {
              "name": "SHA PING BA QU",
              "code": 11
            },
            {
              "name": "BA NAN QU",
              "code": 12
            },
            {
              "name": "FU LING QU",
              "code": 13
            },
            {
              "name": "JIANG BEI QU",
              "code": 14
            },
            {
              "name": "JIU LONG PO QU",
              "code": 15
            },
            {
              "name": "YU ZHONG QU",
              "code": 16
            },
            {
              "name": "QIAN JIANG KAI FA QU",
              "code": 17
            },
            {
              "name": "CHANG SHOU QU",
              "code": 18
            },
            {
              "name": "SHUANG QIAO QU",
              "code": 19
            },
            {
              "name": "QI JIANG XIAN",
              "code": 20
            },
            {
              "name": "TONG NAN XIAN",
              "code": 21
            },
            {
              "name": "TONG LIANG XIAN",
              "code": 22
            },
            {
              "name": "DA ZU XIAN",
              "code": 23
            },
            {
              "name": "RONG CHANG XIAN",
              "code": 24
            },
            {
              "name": "BI SHAN XIAN",
              "code": 25
            },
            {
              "name": "DIAN JIANG XIAN",
              "code": 26
            },
            {
              "name": "WU LONG XIAN",
              "code": 27
            },
            {
              "name": "FENG DU XIAN",
              "code": 28
            },
            {
              "name": "CHENG KOU XIAN",
              "code": 29
            },
            {
              "name": "LIANG PING XIAN",
              "code": 30
            },
            {
              "name": "KAI XIAN",
              "code": 31
            },
            {
              "name": "WU XI XIAN",
              "code": 32
            },
            {
              "name": "WU SHAN XIAN",
              "code": 33
            },
            {
              "name": "FENG JIE XIAN",
              "code": 34
            },
            {
              "name": "YUN YANG XIAN",
              "code": 35
            },
            {
              "name": "ZHONG XIAN",
              "code": 36
            },
            {
              "name": "SHI ZHU",
              "code": 37
            },
            {
              "name": "PENG SHUI",
              "code": 38
            },
            {
              "name": "YOU YANG",
              "code": 39
            },
            {
              "name": "XIU SHAN",
              "code": 40
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "XIANG GANG",
      "code": 32,
      "state": [
        {
          "name": "XIANG GANG",
          "code": 1,
          "city": [
            {
              "name": "SHA TIAN QU",
              "code": 1
            },
            {
              "name": "DONG QU",
              "code": 2
            },
            {
              "name": "GUAN TANG QU",
              "code": 3
            },
            {
              "name": "HUANG DA XIAN QU",
              "code": 4
            },
            {
              "name": "JIU LONG CHENG QU",
              "code": 5
            },
            {
              "name": "TUN MEN QU",
              "code": 6
            },
            {
              "name": "KUI QING QU",
              "code": 7
            },
            {
              "name": "YUAN LANG QU",
              "code": 8
            },
            {
              "name": "SHEN SHUI BU QU",
              "code": 9
            },
            {
              "name": "XI GONG QU",
              "code": 10
            },
            {
              "name": "DA BU QU",
              "code": 11
            },
            {
              "name": "WAN ZAI QU",
              "code": 12
            },
            {
              "name": "YOU JIAN WANG QU",
              "code": 13
            },
            {
              "name": "BEI QU",
              "code": 14
            },
            {
              "name": "NAN QU",
              "code": 15
            },
            {
              "name": "QUAN WAN QU",
              "code": 16
            },
            {
              "name": "ZHONG XI QU",
              "code": 17
            },
            {
              "name": "LI DAO QU",
              "code": 18
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "AO MEN",
      "code": 33,
      "state": [
        {
          "name": "AO MEN",
          "code": 1,
          "city": [
            {
              "name": "AO MEN",
              "code": 1
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "TAI WAN",
      "code": 34,
      "state": [
        {
          "name": "TAI WAN",
          "code": 1,
          "city": [
            {
              "name": "TAI BEI",
              "code": 1
            },
            {
              "name": "GAO XIONG",
              "code": 2
            },
            {
              "name": "JI LONG",
              "code": 3
            },
            {
              "name": "TAI ZHONG",
              "code": 4
            },
            {
              "name": "TAI NAN",
              "code": 5
            },
            {
              "name": "XIN ZHU",
              "code": 6
            },
            {
              "name": "JIA YI",
              "code": 7
            },
            {
              "name": "YI LAN XIAN",
              "code": 8
            },
            {
              "name": "TAO YUAN XIAN",
              "code": 9
            },
            {
              "name": "MIAO LI XIAN",
              "code": 10
            },
            {
              "name": "ZHANG HUA XIAN",
              "code": 11
            },
            {
              "name": "NAN TOU XIAN",
              "code": 12
            },
            {
              "name": "YUN LIN XIAN",
              "code": 13
            },
            {
              "name": "PING DONG XIAN",
              "code": 14
            },
            {
              "name": "TAI DONG XIAN",
              "code": 15
            },
            {
              "name": "HUA LIAN XIAN",
              "code": 16
            },
            {
              "name": "PENG HU XIAN",
              "code": 17
            }
          ]
        }
      ]
    }
  }
]
        }
    }
})