$(document).ready(function () {
    $.areaSelect_resume = function (init) {
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
            html += '<button id="submitADD">ADD</button>';
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

                var initval = $('#hasCheck').val();
                if(initval.length!=0){
                    initval = initval+" / ";
                }

                $('#hasCheck').val(initval+Province);
                $('.tab-list-2 ul').empty();
                $('.tab-list-3 ul').empty();
                createState();
                $('.tab-list-2 li a').click(function () {
                    $(this).parent().addClass('minISClick').siblings().removeClass('minISClick');
                    cityCode = $(this).children('input').val();
                    State = $(this).text();
                    $('#hasCheck').val(initval+Province + '-' + State);
                    $('.tab-list-3 ul').empty();
                    createCity();
                    $('.tab-list-3 li a').click(function () {
                        $(this).parent().addClass('minISClick').siblings().removeClass('minISClick');
                        City = $(this).text();
                        $('#hasCheck').val(initval+Province + '-' + State + '-' + City);
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
        $('#submitADD').click(function () {
            var listOne = $('.tab-list-1');
            listOne.addClass('isBlock').siblings().removeClass('isBlock');
            $('.tab-1').addClass('isCheck').siblings().removeClass('isCheck');
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
      "name": "CHINA",
      "code": 1,
      "state": [
        {
          "name": "BEI JING",
          "code": 1,
          "city": [
            {
              "name": "SHI XIA QU",
              "code": 1
            }
          ]
        },
        {
          "name": "AN HUI",
          "code": 2,
          "city": [
            {
              "name": "AN QING",
              "code": 1
            },
            {
              "name": "BENG BU",
              "code": 2
            },
            {
              "name": "CHAO HU",
              "code": 3
            },
            {
              "name": "CHI ZHOU",
              "code": 4
            },
            {
              "name": "CHU ZHOU",
              "code": 5
            },
            {
              "name": "FU YANG",
              "code": 6
            },
            {
              "name": "HUAI BEI",
              "code": 7
            },
            {
              "name": "HUAI NAN",
              "code": 8
            },
            {
              "name": "HUANG SHAN",
              "code": 9
            },
            {
              "name": "LU AN",
              "code": 10
            },
            {
              "name": "MA AN SHAN",
              "code": 11
            },
            {
              "name": "SU ZHOU",
              "code": 12
            },
            {
              "name": "TONG LING",
              "code": 13
            },
            {
              "name": "WU HU",
              "code": 14
            },
            {
              "name": "XUAN CHENG",
              "code": 15
            },
            {
              "name": "BO ZHOU",
              "code": 16
            },
            {
              "name": "HE FEI",
              "code": 17
            }
          ]
        },
        {
          "name": "FU JIAN",
          "code": 3,
          "city": [
            {
              "name": "FU ZHOU",
              "code": 1
            },
            {
              "name": "LONG YAN",
              "code": 2
            },
            {
              "name": "NAN PING",
              "code": 3
            },
            {
              "name": "NING DE",
              "code": 4
            },
            {
              "name": "PU TIAN",
              "code": 5
            },
            {
              "name": "QUAN ZHOU",
              "code": 6
            },
            {
              "name": "SAN MING",
              "code": 7
            },
            {
              "name": "XIA MEN",
              "code": 8
            },
            {
              "name": "ZHANG ZHOU",
              "code": 9
            }
          ]
        },
        {
          "name": "GAN SU",
          "code": 4,
          "city": [
            {
              "name": "LAN ZHOU",
              "code": 1
            },
            {
              "name": "BAI YIN",
              "code": 2
            },
            {
              "name": "DING XI",
              "code": 3
            },
            {
              "name": "GAN NAN",
              "code": 4
            },
            {
              "name": "JIA YU GUAN",
              "code": 5
            },
            {
              "name": "JIN CHANG",
              "code": 6
            },
            {
              "name": "JIU QUAN",
              "code": 7
            },
            {
              "name": "LIN XIA",
              "code": 8
            },
            {
              "name": "LONG NAN",
              "code": 9
            },
            {
              "name": "PING LIANG",
              "code": 10
            },
            {
              "name": "QING YANG",
              "code": 11
            },
            {
              "name": "TIAN SHUI",
              "code": 12
            },
            {
              "name": "WU WEI",
              "code": 13
            },
            {
              "name": "ZHANG YE",
              "code": 14
            }
          ]
        },
        {
          "name": "GUANG DONG",
          "code": 5,
          "city": [
            {
              "name": "GUANG ZHOU",
              "code": 1
            },
            {
              "name": "SHEN ZHEN",
              "code": 2
            },
            {
              "name": "CHAO ZHOU",
              "code": 3
            },
            {
              "name": "DONG GUAN",
              "code": 4
            },
            {
              "name": "FO SHAN",
              "code": 5
            },
            {
              "name": "HE YUAN",
              "code": 6
            },
            {
              "name": "HUI ZHOU",
              "code": 7
            },
            {
              "name": "JIANG MEN",
              "code": 8
            },
            {
              "name": "JIE YANG",
              "code": 9
            },
            {
              "name": "MAO MING",
              "code": 10
            },
            {
              "name": "MEI ZHOU",
              "code": 11
            },
            {
              "name": "QING YUAN",
              "code": 12
            },
            {
              "name": "SHAN TOU",
              "code": 13
            },
            {
              "name": "SHAN WEI",
              "code": 14
            },
            {
              "name": "SHAO GUAN",
              "code": 15
            },
            {
              "name": "YANG JIANG",
              "code": 16
            },
            {
              "name": "YUN FU",
              "code": 17
            },
            {
              "name": "ZHAN JIANG",
              "code": 18
            },
            {
              "name": "ZHAO QING",
              "code": 19
            },
            {
              "name": "ZHONG SHAN",
              "code": 20
            },
            {
              "name": "ZHU HAI",
              "code": 21
            }
          ]
        },
        {
          "name": "GUANG XI",
          "code": 6,
          "city": [
            {
              "name": "NAN NING",
              "code": 1
            },
            {
              "name": "GUI LIN",
              "code": 2
            },
            {
              "name": "BAI SE",
              "code": 3
            },
            {
              "name": "BEI HAI",
              "code": 4
            },
            {
              "name": "CHONG ZUO",
              "code": 5
            },
            {
              "name": "FANG CHENG GANG",
              "code": 6
            },
            {
              "name": "GUI GANG",
              "code": 7
            },
            {
              "name": "HE CHI",
              "code": 8
            },
            {
              "name": "HE ZHOU",
              "code": 9
            },
            {
              "name": "LAI BIN",
              "code": 10
            },
            {
              "name": "LIU ZHOU",
              "code": 11
            },
            {
              "name": "QIN ZHOU",
              "code": 12
            },
            {
              "name": "WU ZHOU",
              "code": 13
            },
            {
              "name": "YU LIN",
              "code": 14
            }
          ]
        },
        {
          "name": "GUI ZHOU",
          "code": 7,
          "city": [
            {
              "name": "GUI YANG",
              "code": 1
            },
            {
              "name": "AN SHUN",
              "code": 2
            },
            {
              "name": "BI JIE",
              "code": 3
            },
            {
              "name": "LIU PAN SHUI",
              "code": 4
            },
            {
              "name": "QIAN DONG NAN",
              "code": 5
            },
            {
              "name": "QIAN NAN",
              "code": 6
            },
            {
              "name": "QIAN XI NAN",
              "code": 7
            },
            {
              "name": "TONG REN",
              "code": 8
            },
            {
              "name": "ZUN YI",
              "code": 9
            }
          ]
        },
        {
          "name": "HAI NAN",
          "code": 8,
          "city": [
            {
              "name": "HAI KOU",
              "code": 1
            },
            {
              "name": "SAN YA",
              "code": 2
            },
            {
              "name": "BAI SHA",
              "code": 3
            },
            {
              "name": "BAO TING",
              "code": 4
            },
            {
              "name": "CHANG JIANG",
              "code": 5
            },
            {
              "name": "CHENG MAI XIAN",
              "code": 6
            },
            {
              "name": "DING AN XIAN",
              "code": 7
            },
            {
              "name": "DONG FANG",
              "code": 8
            },
            {
              "name": "LE DONG",
              "code": 9
            },
            {
              "name": "LIN GAO XIAN",
              "code": 10
            },
            {
              "name": "LING SHUI",
              "code": 11
            },
            {
              "name": "QIONG HAI",
              "code": 12
            },
            {
              "name": "QIONG ZHONG",
              "code": 13
            },
            {
              "name": "TUN CHANG XIAN",
              "code": 14
            },
            {
              "name": "WAN NING",
              "code": 15
            },
            {
              "name": "WEN CHANG",
              "code": 16
            },
            {
              "name": "WU ZHI SHAN",
              "code": 17
            },
            {
              "name": "DAN ZHOU",
              "code": 18
            }
          ]
        },
        {
          "name": "HE BEI",
          "code": 9,
          "city": [
            {
              "name": "SHI JIA ZHUANG",
              "code": 1
            },
            {
              "name": "BAO DING",
              "code": 2
            },
            {
              "name": "CANG ZHOU",
              "code": 3
            },
            {
              "name": "CHENG DE",
              "code": 4
            },
            {
              "name": "HAN DAN",
              "code": 5
            },
            {
              "name": "HENG SHUI",
              "code": 6
            },
            {
              "name": "LANG FANG",
              "code": 7
            },
            {
              "name": "QIN HUANG DAO",
              "code": 8
            },
            {
              "name": "TANG SHAN",
              "code": 9
            },
            {
              "name": "XING TAI",
              "code": 10
            },
            {
              "name": "ZHANG JIA KOU",
              "code": 11
            }
          ]
        },
        {
          "name": "HE NAN",
          "code": 10,
          "city": [
            {
              "name": "ZHENG ZHOU",
              "code": 1
            },
            {
              "name": "LUO YANG",
              "code": 2
            },
            {
              "name": "KAI FENG",
              "code": 3
            },
            {
              "name": "AN YANG",
              "code": 4
            },
            {
              "name": "HE BI",
              "code": 5
            },
            {
              "name": "JI YUAN",
              "code": 6
            },
            {
              "name": "JIAO ZUO",
              "code": 7
            },
            {
              "name": "NAN YANG",
              "code": 8
            },
            {
              "name": "PING DING SHAN",
              "code": 9
            },
            {
              "name": "SAN MEN XIA",
              "code": 10
            },
            {
              "name": "SHANG QIU",
              "code": 11
            },
            {
              "name": "XIN XIANG",
              "code": 12
            },
            {
              "name": "XIN YANG",
              "code": 13
            },
            {
              "name": "XU CHANG",
              "code": 14
            },
            {
              "name": "ZHOU KOU",
              "code": 15
            },
            {
              "name": "ZHU MA DIAN",
              "code": 16
            },
            {
              "name": "TA HE",
              "code": 17
            },
            {
              "name": "PU YANG",
              "code": 18
            }
          ]
        },
        {
          "name": "HEI LONG JIANG",
          "code": 11,
          "city": [
            {
              "name": "HA ER BIN",
              "code": 1
            },
            {
              "name": "DA QING",
              "code": 2
            },
            {
              "name": "DA XING AN LING",
              "code": 3
            },
            {
              "name": "HE GANG",
              "code": 4
            },
            {
              "name": "HEI HE",
              "code": 5
            },
            {
              "name": "JI XI",
              "code": 6
            },
            {
              "name": "JIA MU SI",
              "code": 7
            },
            {
              "name": "MU DAN JIANG",
              "code": 8
            },
            {
              "name": "QI TAI HE",
              "code": 9
            },
            {
              "name": "QI QI HA ER",
              "code": 10
            },
            {
              "name": "SHUANG YA SHAN",
              "code": 11
            },
            {
              "name": "SUI HUA",
              "code": 12
            },
            {
              "name": "YI CHUN",
              "code": 13
            }
          ]
        },
        {
          "name": "HU BEI",
          "code": 12,
          "city": [
            {
              "name": "WU HAN",
              "code": 1
            },
            {
              "name": "XIAN TAO",
              "code": 2
            },
            {
              "name": "E ZHOU",
              "code": 3
            },
            {
              "name": "HUANG GANG",
              "code": 4
            },
            {
              "name": "HUANG SHI",
              "code": 5
            },
            {
              "name": "JING MEN",
              "code": 6
            },
            {
              "name": "JING ZHOU",
              "code": 7
            },
            {
              "name": "QIAN JIANG",
              "code": 8
            },
            {
              "name": "SHEN NONG JIA LIN QU",
              "code": 9
            },
            {
              "name": "SHI YAN",
              "code": 10
            },
            {
              "name": "SUI ZHOU",
              "code": 11
            },
            {
              "name": "TIAN MEN",
              "code": 12
            },
            {
              "name": "XIAN NING",
              "code": 13
            },
            {
              "name": "XIANG FAN",
              "code": 14
            },
            {
              "name": "XIAO GAN",
              "code": 15
            },
            {
              "name": "YI CHANG",
              "code": 16
            },
            {
              "name": "EN SHI",
              "code": 17
            }
          ]
        },
        {
          "name": "HU NAN",
          "code": 13,
          "city": [
            {
              "name": "CHANG SHA",
              "code": 1
            },
            {
              "name": "ZHANG JIA JIE",
              "code": 2
            },
            {
              "name": "CHANG DE",
              "code": 3
            },
            {
              "name": "CHEN ZHOU",
              "code": 4
            },
            {
              "name": "HENG YANG",
              "code": 5
            },
            {
              "name": "HUAI HUA",
              "code": 6
            },
            {
              "name": "LOU DI",
              "code": 7
            },
            {
              "name": "SHAO YANG",
              "code": 8
            },
            {
              "name": "XIANG TAN",
              "code": 9
            },
            {
              "name": "XIANG XI",
              "code": 10
            },
            {
              "name": "YI YANG",
              "code": 11
            },
            {
              "name": "YONG ZHOU",
              "code": 12
            },
            {
              "name": "YUE YANG",
              "code": 13
            },
            {
              "name": "ZHU ZHOU",
              "code": 14
            }
          ]
        },
        {
          "name": "JI LIN",
          "code": 14,
          "city": [
            {
              "name": "CHANG CHUN",
              "code": 1
            },
            {
              "name": "JI LIN",
              "code": 2
            },
            {
              "name": "BAI CHENG",
              "code": 3
            },
            {
              "name": "BAI SHAN",
              "code": 4
            },
            {
              "name": "LIAO YUAN",
              "code": 5
            },
            {
              "name": "SI PING",
              "code": 6
            },
            {
              "name": "SONG YUAN",
              "code": 7
            },
            {
              "name": "TONG HUA",
              "code": 8
            },
            {
              "name": "YAN BIAN",
              "code": 9
            }
          ]
        },
        {
          "name": "JIANG SU",
          "code": 15,
          "city": [
            {
              "name": "NAN JING",
              "code": 1
            },
            {
              "name": "SU ZHOU",
              "code": 2
            },
            {
              "name": "WU XI",
              "code": 3
            },
            {
              "name": "CHANG ZHOU",
              "code": 4
            },
            {
              "name": "HUAI AN",
              "code": 5
            },
            {
              "name": "LIAN YUN GANG",
              "code": 6
            },
            {
              "name": "NAN TONG",
              "code": 7
            },
            {
              "name": "SU QIAN",
              "code": 8
            },
            {
              "name": "TAI ZHOU",
              "code": 9
            },
            {
              "name": "XU ZHOU",
              "code": 10
            },
            {
              "name": "YAN CHENG",
              "code": 11
            },
            {
              "name": "YANG ZHOU",
              "code": 12
            },
            {
              "name": "ZHEN JIANG",
              "code": 13
            }
          ]
        },
        {
          "name": "JIANG XI",
          "code": 16,
          "city": [
            {
              "name": "NAN CHANG",
              "code": 1
            },
            {
              "name": "FU ZHOU",
              "code": 2
            },
            {
              "name": "GAN ZHOU",
              "code": 3
            },
            {
              "name": "JI AN",
              "code": 4
            },
            {
              "name": "JING DE ZHEN",
              "code": 5
            },
            {
              "name": "JIU JIANG",
              "code": 6
            },
            {
              "name": "PING XIANG",
              "code": 7
            },
            {
              "name": "SHANG RAO",
              "code": 8
            },
            {
              "name": "XIN YU",
              "code": 9
            },
            {
              "name": "YI CHUN",
              "code": 10
            },
            {
              "name": "YING TAN",
              "code": 11
            }
          ]
        },
        {
          "name": "LIAO NING",
          "code": 17,
          "city": [
            {
              "name": "SHEN YANG",
              "code": 1
            },
            {
              "name": "DA LIAN",
              "code": 2
            },
            {
              "name": "AN SHAN",
              "code": 3
            },
            {
              "name": "BEN XI",
              "code": 4
            },
            {
              "name": "ZHAO YANG",
              "code": 5
            },
            {
              "name": "DAN DONG",
              "code": 6
            },
            {
              "name": "FU SHUN",
              "code": 7
            },
            {
              "name": "FU XIN",
              "code": 8
            },
            {
              "name": "HU LU DAO",
              "code": 9
            },
            {
              "name": "JIN ZHOU",
              "code": 10
            },
            {
              "name": "LIAO YANG",
              "code": 11
            },
            {
              "name": "PAN JIN",
              "code": 12
            },
            {
              "name": "TIE LING",
              "code": 13
            },
            {
              "name": "YING KOU",
              "code": 14
            }
          ]
        },
        {
          "name": "NEI MENG GU",
          "code": 18,
          "city": [
            {
              "name": "HU HE HAO TE",
              "code": 1
            },
            {
              "name": "A LA SHAN MENG",
              "code": 2
            },
            {
              "name": "BA YAN NAO ER MENG",
              "code": 3
            },
            {
              "name": "BAO TOU",
              "code": 4
            },
            {
              "name": "CHI FENG",
              "code": 5
            },
            {
              "name": "E ER DUO SI",
              "code": 6
            },
            {
              "name": "HU LUN BEI ER",
              "code": 7
            },
            {
              "name": "TONG LIAO",
              "code": 8
            },
            {
              "name": "WU HAI",
              "code": 9
            },
            {
              "name": "WU LAN CHA BU SHI",
              "code": 10
            },
            {
              "name": "XI LIN GUO LE MENG",
              "code": 11
            },
            {
              "name": "XING AN MENG",
              "code": 12
            }
          ]
        },
        {
          "name": "NING XIA",
          "code": 19,
          "city": [
            {
              "name": "YIN CHUAN",
              "code": 1
            },
            {
              "name": "GU YUAN",
              "code": 2
            },
            {
              "name": "SHI ZUI SHAN",
              "code": 3
            },
            {
              "name": "WU ZHONG",
              "code": 4
            },
            {
              "name": "ZHONG WEI",
              "code": 5
            }
          ]
        },
        {
          "name": "QING HAI",
          "code": 20,
          "city": [
            {
              "name": "XI NING",
              "code": 1
            },
            {
              "name": "GUO LUO",
              "code": 2
            },
            {
              "name": "HAI BEI",
              "code": 3
            },
            {
              "name": "HAI DONG",
              "code": 4
            },
            {
              "name": "HAI NAN",
              "code": 5
            },
            {
              "name": "HAI XI",
              "code": 6
            },
            {
              "name": "HUANG NAN",
              "code": 7
            },
            {
              "name": "YU SHU",
              "code": 8
            }
          ]
        },
        {
          "name": "SHAN DONG",
          "code": 21,
          "city": [
            {
              "name": "JI NAN",
              "code": 1
            },
            {
              "name": "QING DAO",
              "code": 2
            },
            {
              "name": "BIN ZHOU",
              "code": 3
            },
            {
              "name": "DE ZHOU",
              "code": 4
            },
            {
              "name": "DONG YING",
              "code": 5
            },
            {
              "name": "HE ZE",
              "code": 6
            },
            {
              "name": "JI NING",
              "code": 7
            },
            {
              "name": "LAI WU",
              "code": 8
            },
            {
              "name": "LIAO CHENG",
              "code": 9
            },
            {
              "name": "LIN YI",
              "code": 10
            },
            {
              "name": "RI ZHAO",
              "code": 11
            },
            {
              "name": "TAI AN",
              "code": 12
            },
            {
              "name": "WEI HAI",
              "code": 13
            },
            {
              "name": "WEI FANG",
              "code": 14
            },
            {
              "name": "YAN TAI",
              "code": 15
            },
            {
              "name": "ZAO ZHUANG",
              "code": 16
            },
            {
              "name": "ZI BO",
              "code": 17
            }
          ]
        },
        {
          "name": "SHAN XI",
          "code": 22,
          "city": [
            {
              "name": "TAI YUAN",
              "code": 1
            },
            {
              "name": "CHANG ZHI",
              "code": 2
            },
            {
              "name": "DA TONG",
              "code": 3
            },
            {
              "name": "JIN CHENG",
              "code": 4
            },
            {
              "name": "JIN ZHONG",
              "code": 5
            },
            {
              "name": "LIN FEN",
              "code": 6
            },
            {
              "name": "LYU LIANG",
              "code": 7
            },
            {
              "name": "SHUO ZHOU",
              "code": 8
            },
            {
              "name": "XIN ZHOU",
              "code": 9
            },
            {
              "name": "YANG QUAN",
              "code": 10
            },
            {
              "name": "YUN CHENG",
              "code": 11
            }
          ]
        },
        {
          "name": "SHAN XI",
          "code": 23,
          "city": [
            {
              "name": "XI AN",
              "code": 1
            },
            {
              "name": "AN KANG",
              "code": 2
            },
            {
              "name": "BAO JI",
              "code": 3
            },
            {
              "name": "HAN ZHONG",
              "code": 4
            },
            {
              "name": "SHANG LUO",
              "code": 5
            },
            {
              "name": "TONG CHUAN",
              "code": 6
            },
            {
              "name": "WEI NAN",
              "code": 7
            },
            {
              "name": "XIAN YANG",
              "code": 8
            },
            {
              "name": "YAN AN",
              "code": 9
            },
            {
              "name": "YU LIN",
              "code": 10
            }
          ]
        },
        {
          "name": "SHANG HAI",
          "code": 24,
          "city": [
            {
              "name": "SHANG HAI",
              "code": 1
            }
          ]
        },
        {
          "name": "SI CHUAN",
          "code": 25,
          "city": [
            {
              "name": "CHENG DU",
              "code": 1
            },
            {
              "name": "MIAN YANG",
              "code": 2
            },
            {
              "name": "A BA",
              "code": 3
            },
            {
              "name": "BA ZHONG",
              "code": 4
            },
            {
              "name": "DA ZHOU",
              "code": 5
            },
            {
              "name": "DE YANG",
              "code": 6
            },
            {
              "name": "GAN ZI",
              "code": 7
            },
            {
              "name": "GUANG AN",
              "code": 8
            },
            {
              "name": "GUANG YUAN",
              "code": 9
            },
            {
              "name": "LE SHAN",
              "code": 10
            },
            {
              "name": "LIANG SHAN",
              "code": 11
            },
            {
              "name": "MEI SHAN",
              "code": 12
            },
            {
              "name": "NAN CHONG",
              "code": 13
            },
            {
              "name": "NEI JIANG",
              "code": 14
            },
            {
              "name": "PAN ZHI HUA",
              "code": 15
            },
            {
              "name": "SUI NING",
              "code": 16
            },
            {
              "name": "YA AN",
              "code": 17
            },
            {
              "name": "YI BIN",
              "code": 18
            },
            {
              "name": "ZI YANG",
              "code": 19
            },
            {
              "name": "ZI GONG",
              "code": 20
            },
            {
              "name": "LU ZHOU",
              "code": 21
            }
          ]
        },
        {
          "name": "TIAN JIN",
          "code": 26,
          "city": [
            {
              "name": "TIAN JIN",
              "code": 1
            }
          ]
        },
        {
          "name": "XI ZANG",
          "code": 27,
          "city": [
            {
              "name": "LA SA",
              "code": 1
            },
            {
              "name": "A LI",
              "code": 2
            },
            {
              "name": "CHANG DU",
              "code": 3
            },
            {
              "name": "LIN ZHI",
              "code": 4
            },
            {
              "name": "NA QU",
              "code": 5
            },
            {
              "name": "RI KA ZE",
              "code": 6
            },
            {
              "name": "SHAN NAN",
              "code": 7
            }
          ]
        },
        {
          "name": "XIN JIANG",
          "code": 28,
          "city": [
            {
              "name": "WU LU MU QI",
              "code": 1
            },
            {
              "name": "A KE SU",
              "code": 2
            },
            {
              "name": "A LA ER",
              "code": 3
            },
            {
              "name": "BA YIN GUO LENG",
              "code": 4
            },
            {
              "name": "BO ER TA LA",
              "code": 5
            },
            {
              "name": "CHANG JI",
              "code": 6
            },
            {
              "name": "HA MI",
              "code": 7
            },
            {
              "name": "HE TIAN",
              "code": 8
            },
            {
              "name": "KA SHI",
              "code": 9
            },
            {
              "name": "KE LA MA YI",
              "code": 10
            },
            {
              "name": "KE ZI LE SU",
              "code": 11
            },
            {
              "name": "SHI HE ZI",
              "code": 12
            },
            {
              "name": "TU MU SHU KE",
              "code": 13
            },
            {
              "name": "TU LU FAN",
              "code": 14
            },
            {
              "name": "WU JIA QU",
              "code": 15
            },
            {
              "name": "YI LI",
              "code": 16
            }
          ]
        },
        {
          "name": "YUN NAN",
          "code": 29,
          "city": [
            {
              "name": "KUN MING",
              "code": 1
            },
            {
              "name": "NU JIANG",
              "code": 2
            },
            {
              "name": "PU ER",
              "code": 3
            },
            {
              "name": "LI JIANG",
              "code": 4
            },
            {
              "name": "BAO SHAN",
              "code": 5
            },
            {
              "name": "CHU XIONG",
              "code": 6
            },
            {
              "name": "DA LI",
              "code": 7
            },
            {
              "name": "DE HONG",
              "code": 8
            },
            {
              "name": "DI QING",
              "code": 9
            },
            {
              "name": "HONG HE",
              "code": 10
            },
            {
              "name": "LIN CANG",
              "code": 11
            },
            {
              "name": "QU JING",
              "code": 12
            },
            {
              "name": "WEN SHAN",
              "code": 13
            },
            {
              "name": "XI SHUANG BAN NA",
              "code": 14
            },
            {
              "name": "YU XI",
              "code": 15
            },
            {
              "name": "ZHAO TONG",
              "code": 16
            }
          ]
        },
        {
          "name": "ZHE JIANG",
          "code": 30,
          "city": [
            {
              "name": "HANG ZHOU",
              "code": 1
            },
            {
              "name": "HU ZHOU",
              "code": 2
            },
            {
              "name": "JIA XING",
              "code": 3
            },
            {
              "name": "JIN HUA",
              "code": 4
            },
            {
              "name": "LI SHUI",
              "code": 5
            },
            {
              "name": "NING BO",
              "code": 6
            },
            {
              "name": "SHAO XING",
              "code": 7
            },
            {
              "name": "TAI ZHOU",
              "code": 8
            },
            {
              "name": "WEN ZHOU",
              "code": 9
            },
            {
              "name": "ZHOU SHAN",
              "code": 10
            },
            {
              "name": "QU ZHOU",
              "code": 11
            }
          ]
        },
        {
          "name": "CHONG QING",
          "code": 31,
          "city": [
            {
              "name": "CHONG QING",
              "code": 1
            }
          ]
        },
        {
          "name": "XIANG GANG",
          "code": 32,
          "city": [
            {
              "name": "XIANG GANG",
              "code": 1
            }
          ]
        },
        {
          "name": "AO MEN",
          "code": 33,
          "city": [
            {
              "name": "AO MEN",
              "code": 1
            }
          ]
        },
        {
          "name": "TAI WAN",
          "code": 34,
          "city": [
            {
              "name": "TAI WAN",
              "code": 1
            }
          ]
        }
      ]
    }
  },
  {
    "region": {
      "name": "ANDORRA",
      "code": 2,
      "state": []
    }
  },
  {
    "region": {
      "name": "UNITED ARAB EMIRATES",
      "code": 3,
      "state": []
    }
  },
  {
    "region": {
      "name": "AFGHANISTAN",
      "code": 4,
      "state": []
    }
  },
  {
    "region": {
      "name": "ANTIGUA AND BARBUDA",
      "code": 5,
      "state": []
    }
  },
  {
    "region": {
      "name": "ANGUILLA",
      "code": 6,
      "state": []
    }
  },
  {
    "region": {
      "name": "ALBANIA",
      "code": 7,
      "state": []
    }
  },
  {
    "region": {
      "name": "ARMENIA",
      "code": 8,
      "state": []
    }
  },
  {
    "region": {
      "name": "ASCENSION",
      "code": 9,
      "state": []
    }
  },
  {
    "region": {
      "name": "ANGOLA",
      "code": 10,
      "state": []
    }
  },
  {
    "region": {
      "name": "ARGENTINA",
      "code": 11,
      "state": []
    }
  },
  {
    "region": {
      "name": "AUSTRIA",
      "code": 12,
      "state": []
    }
  },
  {
    "region": {
      "name": "AUSTRALIA",
      "code": 13,
      "state": []
    }
  },
  {
    "region": {
      "name": "AZERBAIJAN",
      "code": 14,
      "state": []
    }
  },
  {
    "region": {
      "name": "BARBADOS",
      "code": 15,
      "state": []
    }
  },
  {
    "region": {
      "name": "BANGLADESH",
      "code": 16,
      "state": []
    }
  },
  {
    "region": {
      "name": "BELGIUM",
      "code": 17,
      "state": []
    }
  },
  {
    "region": {
      "name": "BURKINA-FASO",
      "code": 18,
      "state": []
    }
  },
  {
    "region": {
      "name": "BULGARIA",
      "code": 19,
      "state": []
    }
  },
  {
    "region": {
      "name": "BAHRAIN",
      "code": 20,
      "state": []
    }
  },
  {
    "region": {
      "name": "BURUNDI",
      "code": 21,
      "state": []
    }
  },
  {
    "region": {
      "name": "BENIN",
      "code": 22,
      "state": []
    }
  },
  {
    "region": {
      "name": "PALESTINE",
      "code": 23,
      "state": []
    }
  },
  {
    "region": {
      "name": "BERMUDA IS.",
      "code": 24,
      "state": []
    }
  },
  {
    "region": {
      "name": "BRUNEI",
      "code": 25,
      "state": []
    }
  },
  {
    "region": {
      "name": "BOLIVIA",
      "code": 26,
      "state": []
    }
  },
  {
    "region": {
      "name": "BRAZIL",
      "code": 27,
      "state": []
    }
  },
  {
    "region": {
      "name": "BAHAMAS",
      "code": 28,
      "state": []
    }
  },
  {
    "region": {
      "name": "BOTSWANA",
      "code": 29,
      "state": []
    }
  },
  {
    "region": {
      "name": "BELARUS",
      "code": 30,
      "state": []
    }
  },
  {
    "region": {
      "name": "BELIZE",
      "code": 31,
      "state": []
    }
  },
  {
    "region": {
      "name": "CANADA",
      "code": 32,
      "state": []
    }
  },
  {
    "region": {
      "name": "CAYMAN IS.",
      "code": 33,
      "state": []
    }
  },
  {
    "region": {
      "name": "CENTRAL AFRICAN REPUBLIC",
      "code": 34,
      "state": []
    }
  },
  {
    "region": {
      "name": "CONGO(BU)",
      "code": 35,
      "state": []
    }
  },
  {
    "region": {
      "name": "CONGO(DRC)",
      "code": 36,
      "state": []
    }
  },
  {
    "region": {
      "name": "SWITZERLAND",
      "code": 37,
      "state": []
    }
  },
  {
    "region": {
      "name": "COOK IS.",
      "code": 38,
      "state": []
    }
  },
  {
    "region": {
      "name": "CHILE",
      "code": 39,
      "state": []
    }
  },
  {
    "region": {
      "name": "CAMEROON",
      "code": 40,
      "state": []
    }
  },
  {
    "region": {
      "name": "COLOMBIA",
      "code": 42,
      "state": []
    }
  },
  {
    "region": {
      "name": "COSTA RICA",
      "code": 43,
      "state": []
    }
  },
  {
    "region": {
      "name": "CZECH",
      "code": 44,
      "state": []
    }
  },
  {
    "region": {
      "name": "CUBA",
      "code": 45,
      "state": []
    }
  },
  {
    "region": {
      "name": "CYPRUS",
      "code": 46,
      "state": []
    }
  },
  {
    "region": {
      "name": "CZECH REPUBLIC",
      "code": 47,
      "state": []
    }
  },
  {
    "region": {
      "name": "GERMANY",
      "code": 48,
      "state": []
    }
  },
  {
    "region": {
      "name": "DJIBOUTI",
      "code": 49,
      "state": []
    }
  },
  {
    "region": {
      "name": "DENMARK",
      "code": 50,
      "state": []
    }
  },
  {
    "region": {
      "name": "DOMINICA REP.",
      "code": 51,
      "state": []
    }
  },
  {
    "region": {
      "name": "ALGERIA",
      "code": 52,
      "state": []
    }
  },
  {
    "region": {
      "name": "ECUADOR",
      "code": 53,
      "state": []
    }
  },
  {
    "region": {
      "name": "ESTONIA",
      "code": 54,
      "state": []
    }
  },
  {
    "region": {
      "name": "EGYPT",
      "code": 55,
      "state": []
    }
  },
  {
    "region": {
      "name": "SPAIN",
      "code": 56,
      "state": []
    }
  },
  {
    "region": {
      "name": "ETHIOPIA",
      "code": 57,
      "state": []
    }
  },
  {
    "region": {
      "name": "FINLAND",
      "code": 58,
      "state": []
    }
  },
  {
    "region": {
      "name": "FIJI",
      "code": 59,
      "state": []
    }
  },
  {
    "region": {
      "name": "FRANCE",
      "code": 60,
      "state": []
    }
  },
  {
    "region": {
      "name": "GABON",
      "code": 61,
      "state": []
    }
  },
  {
    "region": {
      "name": "UNITED KINGDOM",
      "code": 62,
      "state": []
    }
  },
  {
    "region": {
      "name": "GRENADA",
      "code": 63,
      "state": []
    }
  },
  {
    "region": {
      "name": "GEORGIA",
      "code": 64,
      "state": []
    }
  },
  {
    "region": {
      "name": "FRENCH GUIANA",
      "code": 65,
      "state": []
    }
  },
  {
    "region": {
      "name": "GHANA",
      "code": 66,
      "state": []
    }
  },
  {
    "region": {
      "name": "GIBRALTAR",
      "code": 67,
      "state": []
    }
  },
  {
    "region": {
      "name": "GAMBIA",
      "code": 68,
      "state": []
    }
  },
  {
    "region": {
      "name": "GUINEA",
      "code": 69,
      "state": []
    }
  },
  {
    "region": {
      "name": "GREECE",
      "code": 70,
      "state": []
    }
  },
  {
    "region": {
      "name": "GUATEMALA",
      "code": 71,
      "state": []
    }
  },
  {
    "region": {
      "name": "GUAM",
      "code": 72,
      "state": []
    }
  },
  {
    "region": {
      "name": "GUYANA",
      "code": 73,
      "state": []
    }
  },
  {
    "region": {
      "name": "HONGKONG",
      "code": 74,
      "state": []
    }
  },
  {
    "region": {
      "name": "HONDURAS",
      "code": 75,
      "state": []
    }
  },
  {
    "region": {
      "name": "HAITI",
      "code": 76,
      "state": []
    }
  },
  {
    "region": {
      "name": "HUNGARY",
      "code": 77,
      "state": []
    }
  },
  {
    "region": {
      "name": "INDONESIA",
      "code": 78,
      "state": []
    }
  },
  {
    "region": {
      "name": "IRELAND",
      "code": 79,
      "state": []
    }
  },
  {
    "region": {
      "name": "ISRAEL",
      "code": 80,
      "state": []
    }
  },
  {
    "region": {
      "name": "INDIA",
      "code": 81,
      "state": []
    }
  },
  {
    "region": {
      "name": "IRAQ",
      "code": 82,
      "state": []
    }
  },
  {
    "region": {
      "name": "IRAN",
      "code": 83,
      "state": []
    }
  },
  {
    "region": {
      "name": "ICELAND",
      "code": 84,
      "state": []
    }
  },
  {
    "region": {
      "name": "ITALY",
      "code": 85,
      "state": []
    }
  },
  {
    "region": {
      "name": "IVORY COAST",
      "code": 86,
      "state": []
    }
  },
  {
    "region": {
      "name": "JAMAICA",
      "code": 87,
      "state": []
    }
  },
  {
    "region": {
      "name": "JORDAN",
      "code": 88,
      "state": []
    }
  },
  {
    "region": {
      "name": "JAPAN",
      "code": 89,
      "state": []
    }
  },
  {
    "region": {
      "name": "KENYA",
      "code": 90,
      "state": []
    }
  },
  {
    "region": {
      "name": "KYRGYZSTAN",
      "code": 91,
      "state": []
    }
  },
  {
    "region": {
      "name": "KAMPUCHEA(CAMBODIA)",
      "code": 92,
      "state": []
    }
  },
  {
    "region": {
      "name": "NORTH KOREA",
      "code": 93,
      "state": []
    }
  },
  {
    "region": {
      "name": "KOREA",
      "code": 94,
      "state": []
    }
  },
  {
    "region": {
      "name": "REPUBLIC OF IVORY COAST",
      "code": 95,
      "state": []
    }
  },
  {
    "region": {
      "name": "KUWAIT",
      "code": 96,
      "state": []
    }
  },
  {
    "region": {
      "name": "KAZAKSTAN",
      "code": 97,
      "state": []
    }
  },
  {
    "region": {
      "name": "LAOS",
      "code": 98,
      "state": []
    }
  },
  {
    "region": {
      "name": "LEBANON",
      "code": 99,
      "state": []
    }
  },
  {
    "region": {
      "name": "ST.LUCIA",
      "code": 100,
      "state": []
    }
  },
  {
    "region": {
      "name": "LIECHTENSTEIN",
      "code": 101,
      "state": []
    }
  },
  {
    "region": {
      "name": "SRI LANKA",
      "code": 102,
      "state": []
    }
  },
  {
    "region": {
      "name": "LIBERIA",
      "code": 103,
      "state": []
    }
  },
  {
    "region": {
      "name": "LESOTHO",
      "code": 104,
      "state": []
    }
  },
  {
    "region": {
      "name": "LITHUANIA",
      "code": 105,
      "state": []
    }
  },
  {
    "region": {
      "name": "LUXEMBOURG",
      "code": 106,
      "state": []
    }
  },
  {
    "region": {
      "name": "LATVIA",
      "code": 107,
      "state": []
    }
  },
  {
    "region": {
      "name": "LIBYA",
      "code": 108,
      "state": []
    }
  },
  {
    "region": {
      "name": "MOROCCO",
      "code": 109,
      "state": []
    }
  },
  {
    "region": {
      "name": "MONACO",
      "code": 110,
      "state": []
    }
  },
  {
    "region": {
      "name": "MOLDOVA, REPUBLIC OF",
      "code": 111,
      "state": []
    }
  },
  {
    "region": {
      "name": "MADAGASCAR",
      "code": 112,
      "state": []
    }
  },
  {
    "region": {
      "name": "MALI",
      "code": 113,
      "state": []
    }
  },
  {
    "region": {
      "name": "BURMA",
      "code": 114,
      "state": []
    }
  },
  {
    "region": {
      "name": "MONGOLIA",
      "code": 115,
      "state": []
    }
  },
  {
    "region": {
      "name": "MACAO",
      "code": 116,
      "state": []
    }
  },
  {
    "region": {
      "name": "MONTSERRAT IS",
      "code": 117,
      "state": []
    }
  },
  {
    "region": {
      "name": "MALTA",
      "code": 118,
      "state": []
    }
  },
  {
    "region": {
      "name": "MARIANA IS",
      "code": 119,
      "state": []
    }
  },
  {
    "region": {
      "name": "MARTINIQUE",
      "code": 120,
      "state": []
    }
  },
  {
    "region": {
      "name": "MAURITIUS",
      "code": 121,
      "state": []
    }
  },
  {
    "region": {
      "name": "MALDIVES",
      "code": 122,
      "state": []
    }
  },
  {
    "region": {
      "name": "MALAWI",
      "code": 123,
      "state": []
    }
  },
  {
    "region": {
      "name": "MEXICO",
      "code": 124,
      "state": []
    }
  },
  {
    "region": {
      "name": "MALAYSIA",
      "code": 125,
      "state": []
    }
  },
  {
    "region": {
      "name": "MOZAMBIQUE",
      "code": 126,
      "state": []
    }
  },
  {
    "region": {
      "name": "NAMIBIA",
      "code": 127,
      "state": []
    }
  },
  {
    "region": {
      "name": "NIGER",
      "code": 128,
      "state": []
    }
  },
  {
    "region": {
      "name": "NIGERIA",
      "code": 129,
      "state": []
    }
  },
  {
    "region": {
      "name": "NICARAGUA",
      "code": 130,
      "state": []
    }
  },
  {
    "region": {
      "name": "NETHERLANDS",
      "code": 131,
      "state": []
    }
  },
  {
    "region": {
      "name": "NORWAY",
      "code": 132,
      "state": []
    }
  },
  {
    "region": {
      "name": "NEPAL",
      "code": 133,
      "state": []
    }
  },
  {
    "region": {
      "name": "NETHERIANDS ANTILLES",
      "code": 134,
      "state": []
    }
  },
  {
    "region": {
      "name": "NAURU",
      "code": 135,
      "state": []
    }
  },
  {
    "region": {
      "name": "NEW ZEALAND",
      "code": 136,
      "state": []
    }
  },
  {
    "region": {
      "name": "OMAN",
      "code": 137,
      "state": []
    }
  },
  {
    "region": {
      "name": "PANAMA",
      "code": 138,
      "state": []
    }
  },
  {
    "region": {
      "name": "PERU",
      "code": 139,
      "state": []
    }
  },
  {
    "region": {
      "name": "FRENCH POLYNESIA",
      "code": 140,
      "state": []
    }
  },
  {
    "region": {
      "name": "PAPUA NEW CUINEA",
      "code": 141,
      "state": []
    }
  },
  {
    "region": {
      "name": "PHILIPPINES",
      "code": 142,
      "state": []
    }
  },
  {
    "region": {
      "name": "PAKISTAN",
      "code": 143,
      "state": []
    }
  },
  {
    "region": {
      "name": "POLAND",
      "code": 144,
      "state": []
    }
  },
  {
    "region": {
      "name": "PUERTO RICO",
      "code": 145,
      "state": []
    }
  },
  {
    "region": {
      "name": "PORTUGAL",
      "code": 146,
      "state": []
    }
  },
  {
    "region": {
      "name": "PARAGUAY",
      "code": 147,
      "state": []
    }
  },
  {
    "region": {
      "name": "QATAR",
      "code": 148,
      "state": []
    }
  },
  {
    "region": {
      "name": "REUNION",
      "code": 149,
      "state": []
    }
  },
  {
    "region": {
      "name": "ROMANIA",
      "code": 150,
      "state": []
    }
  },
  {
    "region": {
      "name": "RUSSIA",
      "code": 151,
      "state": []
    }
  },
  {
    "region": {
      "name": "SAUDI ARABIA",
      "code": 152,
      "state": []
    }
  },
  {
    "region": {
      "name": "SOLOMON IS",
      "code": 153,
      "state": []
    }
  },
  {
    "region": {
      "name": "SEYCHELLES",
      "code": 154,
      "state": []
    }
  },
  {
    "region": {
      "name": "SUDAN",
      "code": 155,
      "state": []
    }
  },
  {
    "region": {
      "name": "SWEDEN",
      "code": 156,
      "state": []
    }
  },
  {
    "region": {
      "name": "SINGAPORE",
      "code": 157,
      "state": []
    }
  },
  {
    "region": {
      "name": "SLOVENIA",
      "code": 158,
      "state": []
    }
  },
  {
    "region": {
      "name": "SLOVAKIA",
      "code": 159,
      "state": []
    }
  },
  {
    "region": {
      "name": "SIERRA LEONE",
      "code": 160,
      "state": []
    }
  },
  {
    "region": {
      "name": "SAMOAEASTERN",
      "code": 161,
      "state": []
    }
  },
  {
    "region": {
      "name": "SAN MARINO",
      "code": 162,
      "state": []
    }
  },
  {
    "region": {
      "name": "SENEGAL",
      "code": 163,
      "state": []
    }
  },
  {
    "region": {
      "name": "SOMALI",
      "code": 164,
      "state": []
    }
  },
  {
    "region": {
      "name": "SURINAME",
      "code": 165,
      "state": []
    }
  },
  {
    "region": {
      "name": "SAO TOME AND PRINCIPE",
      "code": 166,
      "state": []
    }
  },
  {
    "region": {
      "name": "SALVADOR",
      "code": 167,
      "state": []
    }
  },
  {
    "region": {
      "name": "SYRIA",
      "code": 168,
      "state": []
    }
  },
  {
    "region": {
      "name": "SWAZILAND",
      "code": 169,
      "state": []
    }
  },
  {
    "region": {
      "name": "CHAD",
      "code": 170,
      "state": []
    }
  },
  {
    "region": {
      "name": "TOGO",
      "code": 171,
      "state": []
    }
  },
  {
    "region": {
      "name": "THAILAND",
      "code": 172,
      "state": []
    }
  },
  {
    "region": {
      "name": "TAJIKSTAN",
      "code": 173,
      "state": []
    }
  },
  {
    "region": {
      "name": "TURKMENISTAN",
      "code": 174,
      "state": []
    }
  },
  {
    "region": {
      "name": "TUNISIA",
      "code": 175,
      "state": []
    }
  },
  {
    "region": {
      "name": "TONGA",
      "code": 176,
      "state": []
    }
  },
  {
    "region": {
      "name": "TURKEY",
      "code": 177,
      "state": []
    }
  },
  {
    "region": {
      "name": "TRINIDAD AND TOBAGO",
      "code": 178,
      "state": []
    }
  },
  {
    "region": {
      "name": "TAIWAN",
      "code": 179,
      "state": []
    }
  },
  {
    "region": {
      "name": "TANZANIA",
      "code": 180,
      "state": []
    }
  },
  {
    "region": {
      "name": "UKRAINE",
      "code": 181,
      "state": []
    }
  },
  {
    "region": {
      "name": "UGANDA",
      "code": 182,
      "state": []
    }
  },
  {
    "region": {
      "name": "UNITED STATES OF AMERICA",
      "code": 183,
      "state": []
    }
  },
  {
    "region": {
      "name": "URUGUAY",
      "code": 184,
      "state": []
    }
  },
  {
    "region": {
      "name": "UZBEKISTAN",
      "code": 185,
      "state": []
    }
  },
  {
    "region": {
      "name": "SAINT VINCENT",
      "code": 186,
      "state": []
    }
  },
  {
    "region": {
      "name": "VENEZUELA",
      "code": 187,
      "state": []
    }
  },
  {
    "region": {
      "name": "VIETNAM",
      "code": 188,
      "state": []
    }
  },
  {
    "region": {
      "name": "YEMEN",
      "code": 189,
      "state": []
    }
  },
  {
    "region": {
      "name": "YUGOSLAVIA",
      "code": 190,
      "state": []
    }
  },
  {
    "region": {
      "name": "SOUTH AFRICA",
      "code": 191,
      "state": []
    }
  },
  {
    "region": {
      "name": "ZAMBIA",
      "code": 192,
      "state": []
    }
  },
  {
    "region": {
      "name": "ZAIRE",
      "code": 193,
      "state": []
    }
  },
  {
    "region": {
      "name": "ZIMBABWE",
      "code": 194,
      "state": []
    }
  },
  {
    "region": {
      "name": "SERBIA",
      "code": 195,
      "state": []
    }
  },
  {
    "region": {
      "name": "NORTH MACEDONIA",
      "code": 196,
      "state": []
    }
  },
  {
    "region": {
      "name": "BOSNIA",
      "code": 197,
      "state": []
    }
  },
  {
    "region": {
      "name": "HERZEGOVINA",
      "code": 198,
      "state": []
    }
  },
  {
    "region": {
      "name": "VATICAN",
      "code": 199,
      "state": []
    }
  },
  {
    "region": {
      "name": "SOUTH SUDAN",
      "code": 200,
      "state": []
    }
  },
  {
    "region": {
      "name": "ERITREA",
      "code": 201,
      "state": []
    }
  },
  {
    "region": {
      "name": "RWANDA",
      "code": 202,
      "state": []
    }
  },
  {
    "region": {
      "name": "MAURITANIA",
      "code": 203,
      "state": []
    }
  },
  {
    "region": {
      "name": "WESTERN SAHARA",
      "code": 204,
      "state": []
    }
  },
  {
    "region": {
      "name": "GUINEA-BISSAU",
      "code": 205,
      "state": []
    }
  },
  {
    "region": {
      "name": "CAPE VERDE",
      "code": 206,
      "state": []
    }
  },
  {
    "region": {
      "name": "CôTE D'IVOIRE",
      "code": 207,
      "state": []
    }
  },
  {
    "region": {
      "name": "EQUATORIAL GUINEA",
      "code": 208,
      "state": []
    }
  },
  {
    "region": {
      "name": "UNION OF COMOROS",
      "code": 209,
      "state": []
    }
  },
  {
    "region": {
      "name": "UNION OF MYANMAR",
      "code": 210,
      "state": []
    }
  },
  {
    "region": {
      "name": "FEDERATED STATES OF MICRONESIA",
      "code": 211,
      "state": []
    }
  },
  {
    "region": {
      "name": "DEMOCRATIC REPUBLIC OF TIMOR-LESTE",
      "code": 212,
      "state": []
    }
  },
  {
    "region": {
      "name": "TUVALU",
      "code": 213,
      "state": []
    }
  },
  {
    "region": {
      "name": "VANUATU",
      "code": 214,
      "state": []
    }
  }
]
        }
    }
})