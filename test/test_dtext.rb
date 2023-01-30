# frozen_string_literal: true

require "dtext"
require "cgi"
require "minitest/autorun"

class DTextTest < Minitest::Test
  def parse(*args, **options)
    DText.parse(*args, **options)
  end

  def parse_inline(dtext)
    parse(dtext, inline: true)
  end

  def assert_parse_id_link(class_name, url, input)
    if url[0] == "/"
      assert_parse(%{<p><a class="dtext-link dtext-id-link #{class_name}" href="#{url}">#{input}</a></p>}, input)
      assert_parse(%{<p><a class="dtext-link dtext-id-link #{class_name}" href="http://danbooru.donmai.us#{url}">#{input}</a></p>}, input, base_url: "http://danbooru.donmai.us")
    else
      assert_parse(%{<p><a rel="external nofollow noreferrer" class="dtext-link dtext-id-link #{class_name}" href="#{url}">#{input}</a></p>}, input)
      assert_parse(%{<p><a rel="external nofollow noreferrer" class="dtext-link dtext-id-link #{class_name}" href="#{url}">#{input}</a></p>}, input, base_url: "http://danbooru.donmai.us")
    end
  end

  def assert_parse(expected, input, **options)
    if expected.nil?
      assert_nil(parse(input, **options))
    else
      assert_equal(expected, parse(input, **options), "DText: #{input}")
    end
  end

  def assert_inline_parse(expected, input)
    assert_parse(expected, input, inline: true)
  end

  def test_relative_urls
    assert_parse('<p><a class="dtext-link dtext-id-link dtext-post-id-link" href="http://danbooru.donmai.us/posts/1234">post #1234</a></p>', "post #1234", base_url: "http://danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="http://danbooru.donmai.us/wiki_pages/touhou">touhou</a></p>', "[[touhou]]", base_url: "http://danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="http://danbooru.donmai.us/wiki_pages/touhou">Touhou</a></p>', "[[touhou|Touhou]]", base_url: "http://danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link dtext-post-search-link" href="http://danbooru.donmai.us/posts?tags=touhou">touhou</a></p>', "{{touhou}}", base_url: "http://danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link dtext-id-link dtext-forum-topic-id-link" href="http://danbooru.donmai.us/forum_topics/1234?page=4">topic #1234/p4</a></p>', "topic #1234/p4", base_url: "http://danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="http://danbooru.donmai.us/posts">home</a></p>', '"home":/posts', base_url: "http://danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="http://danbooru.donmai.us#posts">home</a></p>', '"home":#posts', base_url: "http://danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="http://danbooru.donmai.us/posts">home</a></p>', '<a href="/posts">home</a>', base_url: "http://danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="http://danbooru.donmai.us#posts">home</a></p>', '<a href="#posts">home</a>', base_url: "http://danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="evazion" href="http://danbooru.donmai.us/users?name=evazion">@evazion</a></p>', "@evazion", base_url: "http://danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="evazion" href="http://danbooru.donmai.us/users?name=evazion">@evazion</a></p>', "<@evazion>", base_url: "http://danbooru.donmai.us")
  end

  def test_args
    assert_parse(nil, nil)
    assert_parse("", "")
    assert_raises(TypeError) { parse(42) }
  end

  def test_mentions
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="bob" href="/users?name=bob">@bob</a></p>', "@bob")
    assert_parse('<p>hi <a class="dtext-link dtext-user-mention-link" data-user-name="bob" href="/users?name=bob">@bob</a></p>', "hi @bob")
    assert_parse('<p>this is not @.@ @_@ <a class="dtext-link dtext-user-mention-link" data-user-name="bob" href="/users?name=bob">@bob</a></p>', "this is not @.@ @_@ @bob")
    assert_parse('<p>multiple <a class="dtext-link dtext-user-mention-link" data-user-name="bob" href="/users?name=bob">@bob</a> <a class="dtext-link dtext-user-mention-link" data-user-name="anna" href="/users?name=anna">@anna</a></p>', "multiple @bob @anna")

    # assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="bob" href="/users?name=bob">@bob</a>\'s</p>', "@bob's")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="bob\'s" href="/users?name=bob%27s">@bob\'s</a></p>', "@bob's") # XXX shouldn't include apostrophe

    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="_cf" href="/users?name=_cf">@_cf</a></p>', "@_cf")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="_dk" href="/users?name=_dk">@_dk</a></p>', "@_dk")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name=".musouka" href="/users?name=.musouka">@.musouka</a></p>', "@.musouka")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name=".dank" href="/users?name=.dank">@.dank</a></p>', "@.dank")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="games.2019" href="/users?name=games.2019">@games.2019</a></p>', "@games.2019")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name=".k1.38+23" href="/users?name=.k1.38%2B23">@.k1.38+23</a></p>', "@.k1.38+23")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="PostIt-Notes" href="/users?name=PostIt-Notes">@PostIt-Notes</a></p>', "@PostIt-Notes")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="Équi_libriste" href="/users?name=%C3%89qui_libriste">@Équi_libriste</a></p>', "@Équi_libriste")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="111K女" href="/users?name=111K%E5%A5%B3">@111K女</a></p>', "@111K女")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="🌟💖🌈RainbowStarblast🌈💖🌟" href="/users?name=%F0%9F%8C%9F%F0%9F%92%96%F0%9F%8C%88RainbowStarblast%F0%9F%8C%88%F0%9F%92%96%F0%9F%8C%9F">@🌟💖🌈RainbowStarblast🌈💖🌟</a></p>', "@🌟💖🌈RainbowStarblast🌈💖🌟")

    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="　初　音　ミ　ク" href="/users?name=%E3%80%80%E5%88%9D%E3%80%80%E9%9F%B3%E3%80%80%E3%83%9F%E3%80%80%E3%82%AF">@　初　音　ミ　ク</a></p>', "@　初　音　ミ　ク") # XXX shouldn't work

    # assert_parse('<p>@http://en.or.tp/~suzuran/</p>', "@http://en.or.tp/~suzuran/") # XXX shouldn't work
    # assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="[KN]" href="/users?name=[KN]">@[KN]</a></p>', "@[KN]") # XXX should work
    # assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="|Leo|" href="/users?name=|Leo|">@|Leo|</a></p>', "@|Leo|") # XXX should work
    # assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="-abraxas-" href="/users?name=-abraxas-">@-abraxas-</a></p>', "@-abraxas-") # should work
    # assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="-Yangbojian" href="/users?name=-Yanbojian">@-Yangbojian</a></p>', "@-Yangbojian") # should work
  end

  def test_nonmentions
    assert_parse('<p>@@</p>', "@@")
    assert_parse('<p>@+</p>', "@+")
    assert_parse('<p>@_</p>', "@_")
    assert_parse('<p>@?</p>', "@?")
    assert_parse('<p>@N</p>', "@N")
    assert_parse('<p>@$$</p>', "@$$")
    assert_parse('<p>@%%</p>', "@%%")
    assert_parse('<p>@.@</p>', "@.@")
    assert_parse('<p>@.o</p>', "@.o")
    assert_parse('<p>@_o</p>', "@_o")
    assert_parse('<p>@_X</p>', "@_X")
    assert_parse('<p>@_@</p>', "@_@")
    assert_parse('<p>@¬@</p>', "@¬@")
    assert_parse('<p>@w@</p>', "@w@")
    assert_parse('<p>@n@</p>', "@n@")
    assert_parse('<p>@A@</p>', "@A@")
    assert_parse('<p>@3@</p>', "@3@")
    assert_parse('<p>@__X</p>', "@__X")
    assert_parse('<p>@__@</p>', "@__@")
    assert_parse('<p>@_@k</p>', "@_@k")
    assert_parse('<p>@_@&quot;</p>', '@_@"')
    assert_parse('<p>@_@:</p>', "@_@:")
    assert_parse('<p>@_@,.</p>', "@_@,.")
    assert_parse('<p>@_@...</p>', "@_@...")
    assert_parse('<p>@_@!~</p>', "@_@!~")
    assert_parse('<p>@(_   _)</p>', "@(_   _)")
    assert_parse('<p>@_@[/quote]</p>', "@_@[/quote]")
    assert_parse('<p>@///@</p>', "@///@")
    assert_parse('<p>@===&gt;</p>', "@===>")
    assert_parse('<p>@#(&amp;*.</p>', "@#(&*.")
    assert_parse('<p>@*$-pull</p>', "@*$-pull")
    assert_parse('<p>@@</p>', "@@")
    assert_parse('<p>@@,but</p>', "@@,but")
    assert_parse('<p> @: </p>', " @: ")
    assert_parse('<p> @, </p>', " @, ")
    assert_parse('<p>@/\/\ao</p>', '@/\/\ao')
    assert_parse('<p>@.@;;;</p>', "@.@;;;")
    assert_parse("<p>@'d</p>", "@'d")
    assert_parse("<p>@'ing</p>", "@'ing")
    assert_parse('<p>@-like</p>', "@-like")
    assert_parse('<p>@-chan</p>', "@-chan")
    assert_parse('<p>@-mention</p>', "@-mention")
    assert_parse('<p>@-moz-document</p>', "@-moz-document")
    assert_parse('<p>@&quot;I love ProgRock&quot;</p>', '@"I love ProgRock"')
    assert_parse('<p>@@text</p>', "@@text")
    assert_parse('<p>@o@</p>', "@o@")

    assert_parse('<p>email@address.com</p>', "email@address.com")
    assert_parse('<p>idolm@ster</p>', 'idolm@ster')

    assert_parse('<p>@<strong>Biribiri-chan</strong></p>', '@[b]Biribiri-chan[/b]')
    assert_parse('<p>@<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="https://twitter.com/eshaolang">@eshaolang</a></p>', '@"@eshaolang":[https://twitter.com/eshaolang]')
  end

  def test_disabled_mentions
    assert_parse('<p>@bob</p>', "@bob", disable_mentions: true)
    assert_parse('<p>&lt;@bob&gt;</p>', "<@bob>", disable_mentions: true)

    assert_parse('<p>@bob<em>blah</em></p>', "@bob[i]blah[/i]", disable_mentions: true)
    assert_parse('<p>&lt;@bob<em>blah</em>&gt;</p>', "<@bob[i]blah[/i]>", disable_mentions: true)
    assert_parse('<p>@<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="https://twitter.com/eshaolang">@eshaolang</a></p>', '@"@eshaolang":[https://twitter.com/eshaolang]', disable_mentions: true)
  end

  def test_sanitize_heart
    assert_parse('<p>&lt;3</p>', "<3")
  end

  def test_sanitize_less_than
    assert_parse('<p>&lt;</p>', "<")
  end

  def test_sanitize_greater_than
    assert_parse('<p>&gt;</p>', ">")
  end

  def test_sanitize_ampersand
    assert_parse('<p>&amp;</p>', "&")
  end

  def test_wiki_links
    assert_parse("<p>a <a class=\"dtext-link dtext-wiki-link\" href=\"/wiki_pages/b\">b</a> c</p>", "a [[b]] c")
    assert_parse("<p><a class=\"dtext-link dtext-wiki-link\" href=\"/wiki_pages/%E6%9D%B1%E6%96%B9\">東方</a></p>", "[[東方]]")
  end

  def test_wiki_links_spoiler
    assert_parse("<p>a <a class=\"dtext-link dtext-wiki-link\" href=\"/wiki_pages/spoiler\">spoiler</a> c</p>", "a [[spoiler]] c")
  end

  def test_wiki_links_edge
    assert_parse("<p>[[|_|]]</p>", "[[|_|]]")
    assert_parse("<p>[[||_||]]</p>", "[[||_||]]")
  end

  def test_wiki_links_nested_b
    assert_parse("<p><strong>[[</strong>tag<strong>]]</strong></p>", "[b][[[/b]tag[b]]][/b]")
  end

  def test_wiki_links_suffixes
    assert_parse('<p>I like <a class="dtext-link dtext-wiki-link" href="/wiki_pages/cat">cats</a>.</p>', "I like [[cat]]s.")
    assert_parse('<p>a <a class="dtext-link dtext-wiki-link" href="/wiki_pages/cat">cat</a>\'s paw</p>', "a [[cat]]'s paw")
    assert_parse('<p>the <a class="dtext-link dtext-wiki-link" href="/wiki_pages/60s">1960s</a>.</p>', "the 19[[60s]].")
    assert_parse('<p>a <a class="dtext-link dtext-wiki-link" href="/wiki_pages/c">bcd</a> e</p>', "a b[[c]]d e")

    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="/wiki_pages/b">acd</a></p>', "a[[b|c]]d")
  end

  def test_wiki_links_pipe_trick
    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="/wiki_pages/tagme">tagme</a></p>', "[[tagme|]]")
    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="/wiki_pages/tagme">TAGME</a></p>', "[[TAGME|]]")
    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="/wiki_pages/foo_%28bar%29">foo</a></p>', "[[foo (bar)|]]")
    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="/wiki_pages/foo_%28bar%29">abcfoo123</a></p>', "abc[[foo (bar)|]]123")

    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="/wiki_pages/kaga_%28kantai_collection%29">kaga</a></p>', "[[kaga_(kantai_collection)|]]")
    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="/wiki_pages/kaga_%28kantai_collection%29">Kaga</a></p>', "[[Kaga (Kantai Collection)|]]")
    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="/wiki_pages/kaga_%28kantai_collection%29_%28cosplay%29">kaga (kantai collection)</a></p>', "[[kaga (kantai collection) (cosplay)|]]")
  end

  def test_spoilers
    assert_parse("<p>this is <span class=\"spoiler\">an inline spoiler</span>.</p>", "this is [spoiler]an inline spoiler[/spoiler].")
    assert_parse("<p>this is <span class=\"spoiler\">an inline spoiler</span>.</p>", "this is [SPOILERS]an inline spoiler[/SPOILERS].")
    assert_parse("<p>this is</p><div class=\"spoiler\"><p>a block spoiler</p></div><p>.</p>", "this is\n\n[spoiler]\na block spoiler\n[/spoiler].")
    assert_parse("<p>this is</p><div class=\"spoiler\"><p>a block spoiler</p></div><p>.</p>", "this is\n\n[SPOILERS]\na block spoiler\n[/SPOILERS].")
    assert_parse("<div class=\"spoiler\"><p>this is a spoiler with no closing tag</p><p>new text</p></div>", "[spoiler]this is a spoiler with no closing tag\n\nnew text")
    assert_parse("<div class=\"spoiler\"><p>this is a spoiler with no closing tag<br>new text</p></div>", "[spoiler]this is a spoiler with no closing tag\nnew text")
    assert_parse("<div class=\"spoiler\"><p>this is a block spoiler with no closing tag</p></div>", "[spoiler]\nthis is a block spoiler with no closing tag")
    assert_parse("<div class=\"spoiler\"><p>this is <span class=\"spoiler\">a nested</span> spoiler</p></div>", "[spoiler]this is [spoiler]a nested[/spoiler] spoiler[/spoiler]")

    # assert_parse('<div class="spoiler"><h4>Blah</h4></div>', "[spoiler]\nh4. Blah\n[/spoiler]")
    assert_parse(%{<div class="spoiler"><h4>Blah\n[/spoiler]</h4></div>}, "[spoiler]\nh4. Blah\n[/spoiler]") # XXX wrong

    # assert_parse('<p>First sentence</p><p>[/spoiler] Second sentence.</p>', "First sentence\n\n[/spoiler] Second sentence.")
    assert_parse("<p>First sentence</p>\n\n[/spoiler] Second sentence.", "First sentence\n\n[/spoiler] Second sentence.") # XXX wrong

    assert_parse('<p>inline <em>foo</em></p><div class="spoiler"><p>blah blah</p></div>', "inline [i]foo\n\n[spoiler]blah blah[/spoiler]")
    assert_parse('<p>inline <span class="spoiler"> foo</span></p><div class="spoiler"><p>blah blah</p></div>', "inline [spoiler] foo\n\n[spoiler]blah blah[/spoiler]")
  end

  def test_paragraphs
    assert_parse("<p>abc</p>", "abc")
  end

  def test_paragraphs_with_newlines_1
    assert_parse("<p>a<br>b<br>c</p>", "a\nb\nc")
  end

  def test_paragraphs_with_newlines_2
    assert_parse("<p>a</p><p>b</p>", "a\n\nb")
  end

  def test_headers
    assert_parse("<h1>header</h1>", "h1. header")
    assert_parse("<ul><li>a</li></ul><h1>header</h1><ul><li>list</li></ul>", "* a\n\nh1. header\n* list")
  end

  def test_inline_headers
    assert_parse("<p>blah h1. blah</p>", "blah h1. blah")
  end

  def test_headers_with_ids
    assert_parse("<h1 id=\"dtext-blah-blah\">header</h1>", "h1#blah-blah. header")
  end

  def test_headers_with_ids_with_quote
    assert_parse("<p>h1#blah-&quot;blah. header</p>", "h1#blah-\"blah. header")
  end

  def test_inline_elements
    assert_inline_parse("<strong>foo</strong>", "[b]foo[/b]")
    assert_inline_parse("<strong>foo</strong>", "<b>foo</b>")
    assert_inline_parse("<strong>foo</strong>", "<strong>foo</strong>")

    assert_inline_parse("<em>foo</em>", "[i]foo[/i]")
    assert_inline_parse("<em>foo</em>", "<i>foo</i>")
    assert_inline_parse("<em>foo</em>", "<em>foo</em>")

    assert_inline_parse("<s>foo</s>", "[s]foo[/s]")
    assert_inline_parse("<s>foo</s>", "<s>foo</s>")

    assert_inline_parse("<u>foo</u>", "[u]foo[/u]")
    assert_inline_parse("<u>foo</u>", "<u>foo</u>")
  end

  def test_inline_tn
    assert_parse('<p>foo <span class="tn">bar</span> baz</p>', "foo [tn]bar[/tn] baz")
    assert_parse('<p>foo <span class="tn">bar</span> baz</p>', "foo <tn>bar</tn> baz")

    assert_parse('<p>foo bar[/tn] baz</p>', "foo bar[/tn] baz")
    assert_parse('<p>foo bar&lt;/tn&gt; baz</p>', "foo bar</tn> baz")
    assert_parse('<ul><li>foo [/tn] bar</li></ul>', "* foo [/tn] bar")
    assert_parse('<h4>foo [/tn] bar</h4>', "h4. foo [/tn] bar")
    assert_parse('<blockquote><p>foo [/tn] bar</p></blockquote>', "[quote]\nfoo [/tn] bar\n[/quote]")
  end

  def test_block_tn
    assert_parse('<p class="tn">bar</p>', "[tn]bar[/tn]")
    assert_parse('<p class="tn">bar</p>', "<tn>bar</tn>")
  end

  def test_quote_blocks
    assert_parse('<blockquote><p>test</p></blockquote>', "[quote]\ntest\n[/quote]")
    assert_parse('<blockquote><p>test</p></blockquote>', "<quote>\ntest\n</quote>")

    assert_parse('<blockquote><p>test</p></blockquote>', "[quote]\ntest\n[/quote] ")
    assert_parse('<blockquote><p>test</p></blockquote><p>blah</p>', "[quote]\ntest\n[/quote] blah")
    assert_parse('<blockquote><p>test</p></blockquote><p>blah</p>', "[quote]\ntest\n[/quote] \nblah")
    assert_parse('<blockquote><p>test</p></blockquote><p>blah</p>', "[quote]\ntest\n[/quote]\nblah")
    assert_parse('<blockquote><p>test</p></blockquote><p> blah</p>', "[quote]\ntest\n[/quote]\n blah") # XXX should ignore space

    assert_parse('<p>test<br>[/quote] blah</p>', "test\n[/quote] blah")
    assert_parse('<p>test<br>[/quote]</p><ul><li>blah</li></ul>', "test\n[/quote]\n* blah")

    assert_parse('<blockquote><p>test</p></blockquote><h4>See also</h4>', "[quote]\ntest\n[/quote]\nh4. See also")
    assert_parse('<blockquote><p>test</p></blockquote><div class="spoiler"><p>blah</p></div>', "[quote]\ntest\n[/quote]\n[spoiler]blah[/spoiler]")

    assert_parse("<p>inline </p><blockquote><p>blah blah</p></blockquote>", "inline [quote]blah blah[/quote]")
    assert_parse("<p>inline <em>foo </em></p><blockquote><p>blah blah</p></blockquote>", "inline [i]foo [quote]blah blah[/quote]")
    assert_parse('<p>inline <span class="spoiler">foo </span></p><blockquote><p>blah blah</p></blockquote>', "inline [spoiler]foo [quote]blah blah[/quote]")

    assert_parse("<p>inline <em>foo</em></p><blockquote><p>blah blah</p></blockquote>", "inline [i]foo\n\n[quote]blah blah[/quote]")
    assert_parse('<p>inline <span class="spoiler">foo </span></p><blockquote><p>blah blah</p></blockquote>', "inline [spoiler]\n\nfoo [quote]blah blah[/quote]")
  end

  def test_quote_blocks_with_list
    assert_parse("<blockquote><ul><li>hello</li><li>there</li></ul></blockquote><p>abc</p>", "[quote]\n* hello\n* there\n[/quote]\nabc")
    assert_parse("<blockquote><ul><li>hello</li><li>there</li></ul></blockquote><p>abc</p>", "[quote]\n* hello\n* there\n\n[/quote]\nabc")
  end

  def test_quote_with_unclosed_tags
    assert_parse('<blockquote><p><strong>foo</strong></p></blockquote>', "[quote][b]foo[/quote]")
    assert_parse('<blockquote><blockquote><p>foo</p></blockquote></blockquote>', "[quote][quote]foo[/quote]")
    assert_parse('<blockquote><div class="spoiler"><p>foo</p></div></blockquote>', "[quote][spoiler]foo[/quote]")
    assert_parse('<blockquote><pre>foo[/quote]</pre></blockquote>', "[quote][code]foo[/quote]")
    assert_parse('<blockquote><details><summary>Show</summary><div><p>foo</p></div></details></blockquote>', "[quote][expand]foo[/quote]")
    assert_parse('<blockquote><p>foo[/quote]</p></blockquote>', "[quote][nodtext]foo[/quote]")
    assert_parse('<blockquote><table class="striped"><td>foo</td></table></blockquote>', "[quote][table][td]foo[/quote]")
    assert_parse('<blockquote><ul><li>foo</li></ul></blockquote>', "[quote]* foo[/quote]")
    assert_parse('<blockquote><h1>foo</h1></blockquote>', "[quote]h1. foo[/quote]")
  end

  def test_quote_blocks_nested
    assert_parse("<blockquote><p>a</p><blockquote><p>b</p></blockquote><p>c</p></blockquote>", "[quote]\na\n[quote]\nb\n[/quote]\nc\n[/quote]")
  end

  def test_quote_blocks_nested_spoiler
    assert_parse("<blockquote><p>a<br><span class=\"spoiler\">blah</span><br>c</p></blockquote>", "[quote]\na\n[spoiler]blah[/spoiler]\nc[/quote]")
    assert_parse("<blockquote><p>a</p><div class=\"spoiler\"><p>blah</p></div><p>c</p></blockquote>", "[quote]\na\n\n[spoiler]blah[/spoiler]\n\nc[/quote]")

    assert_parse('<details><summary>Show</summary><div><div class="spoiler"><ul><li>blah</li></ul></div></div></details>', "[expand]\n[spoiler]\n* blah\n[/spoiler]\n[/expand]")
  end

  def test_quote_blocks_nested_expand
    assert_parse("<blockquote><p>a</p><details><summary>Show</summary><div><p>b</p></div></details><p>c</p></blockquote>", "[quote]\na\n[expand]\nb\n[/expand]\nc\n[/quote]")
  end

  def test_block_code
    assert_parse("<pre>for (i=0; i&lt;5; ++i) {\n  printf(1);\n}\n\nexit(1);</pre>", "[code]for (i=0; i<5; ++i) {\n  printf(1);\n}\n\nexit(1);")
    assert_parse("<pre>[b]lol[/b]</pre>", "[code][b]lol[/b][/code]")
    assert_parse("<pre>[code]</pre>", "[code][code][/code]")
    assert_parse("<pre>post #123</pre>", "[code]post #123[/code]")
    assert_parse("<pre>x</pre>", "[code]x")
  end

  def test_inline_code
    assert_parse("<p>foo <code>[b]lol[/b]</code>.</p>", "foo [code][b]lol[/b][/code].")
    assert_parse("<p>foo <code>[code]</code>.</p>", "foo [code][code][/code].")
    assert_parse("<p>foo <em><code>post #123</code></em>.</p>", "foo [i][code]post #123[/code][/i].")
    assert_parse("<p>foo <code>x</code></p>", "foo [code]x")
  end

  def test_code_fence
    assert_parse('<pre>code</pre>', "```\ncode\n```")
    assert_parse('<pre>code</pre>', "``` \ncode\n``` ")
    assert_parse("<pre>\ncode\n</pre>", "```\n\ncode\n\n```")
    assert_parse("<pre>\n\ncode\n\n</pre>", "```\n\n\ncode\n\n\n```")
    assert_parse("<pre>one\ntwo\nthree</pre>", "```\none\ntwo\nthree\n```")

    assert_parse('<p>````<br>code<br>```</p>', "````\ncode\n```")
    assert_parse('<p>```<br>code<br>````</p>', "```\ncode\n````")

    assert_parse('<p>```<br>```</p>', "```\n```") # XXX wrong? should allow empty code blocks
    assert_parse('<pre></pre>', "```\n\n```")

    assert_parse('<pre>&lt;b&gt;</pre>', "```\n<b>\n```")

    assert_parse('<p>text</p><pre>code</pre>', "text\n\n```\ncode\n```")
    assert_parse('<p>text</p><pre>code</pre>', "text\n```\ncode\n```")
    assert_parse('<pre>code</pre><p>text</p>', "```\ncode\n```\n\ntext")
    assert_parse('<pre>code</pre><p>text</p>', "```\ncode\n```\ntext")
    assert_parse('<p>text</p><pre>code</pre><p>text</p>', "text\n```\ncode\n```\ntext")
    assert_parse('<p>text</p><pre>code</pre><p>text</p>', "text\n\n\n\n```\ncode\n```\n\n\n\ntext")

    assert_parse('<pre>one</pre><p>two<br>```</p>', "```\none\n```\ntwo\n```")
    assert_parse('<pre>one</pre><p>two</p><p>```</p>', "```\none\n```\ntwo\n\n```")
    assert_parse('<pre>one</pre><p>two</p><pre>three</pre>', "```\none\n```\ntwo\n```\nthree\n```")
    assert_parse('<pre>one</pre><p>two</p><pre>three</pre>', "```\none\n```\ntwo\n\n```\nthree\n```")

    assert_parse('<p>text</p><p>x```<br>code<br>```</p>', "text\n\nx```\ncode\n```")
    assert_parse('<p>text</p><p> ```<br>code<br>```</p>', "text\n\n ```\ncode\n```")

    assert_parse('<p>x ```<br>code<br>```</p>', "x ```\ncode\n```")
    assert_parse('<p> ```<br>code<br>```</p>', " ```\ncode\n```")
    assert_parse('<p>```code```</p>', "```code```")
    assert_parse('<p>```<br>code```</p>', "```\ncode```")
    assert_parse('<p>```code<br>```</p>', "```code\n```")
    assert_parse('<p>```code</p>', "```code")
    assert_parse('<p>```<br>code</p>', "```\ncode")
    assert_parse('<p>```</p>', "```")

    assert_parse('<h4>Code</h4><pre>code</pre>', "h4. Code\n```\ncode\n```")
    assert_parse('<ul><li>list</li></ul><pre>code</pre>', "* list\n```\ncode\n```")
    assert_parse('<hr><pre>code</pre>', "[hr]\n```\ncode\n```")

    assert_parse('<p><strong>text</strong></p><pre>code</pre>', "[b]text\n```\ncode\n```")
    assert_parse('<p><em>text</em></p><pre>code</pre>', "[i]text\n```\ncode\n```")
    assert_parse('<p><u>text</u></p><pre>code</pre>', "[u]text\n```\ncode\n```")
    assert_parse('<p><s>text</s></p><pre>code</pre>', "[s]text\n```\ncode\n```")

    assert_parse('<p>inline <span class="tn">text</span></p><pre>code</pre>', "inline [tn]text\n```\ncode\n```")
    assert_parse('<p>inline <span class="spoiler">text</span></p><pre>code</pre>', "inline [spoiler]text\n```\ncode\n```")

    # assert_parse('<p>inline text</p><pre>code</pre>', "inline [nodtext]text\n```\ncode\n```")
    assert_parse("<p>inline text\n```\ncode\n```</p>", "inline [nodtext]text\n```\ncode\n```") # XXX wrong, inline [nodtext] should end at end of line

    # assert_parse('<p>inline <code>text</code></p><pre>code</pre>', "inline [code]text\n```\ncode\n```")
    assert_parse("<p>inline <code>text\n```\ncode\n```</code></p>", "inline [code]text\n```\ncode\n```") # XXX wrong, inline [code] should end at end of line

    assert_parse('<blockquote><pre>code</pre></blockquote>', "[quote]\n```\ncode\n```\n[/quote]")
    assert_parse('<blockquote><pre>code</pre></blockquote>', "[quote]\n```\ncode\n```")
    assert_parse('<blockquote><pre>[/quote]</pre></blockquote>', "[quote]\n```\n[/quote]\n```")
    assert_parse('<div class="spoiler"><pre>code</pre></div>', "[spoiler]\n```\ncode\n```\n[/spoiler]")
    assert_parse('<div class="spoiler"><pre>code</pre></div>', "[spoiler]\n```\ncode\n```")
    assert_parse('<details><summary>Show</summary><div><pre>code</pre></div></details>', "[expand]\n```\ncode\n```\n[/expand]")
    assert_parse('<details><summary>Show</summary><div><pre>code</pre></div></details>', "[expand]\n```\ncode\n```")
    assert_parse("<pre>```\ncode\n```\n</pre>", "[code]\n```\ncode\n```\n[/code]")
    assert_parse("<p>```\ncode\n```\n</p>", "[nodtext]\n```\ncode\n```\n[/nodtext]")
    assert_parse('<p class="tn"><pre>code</pre></p>', "[tn]\n```\ncode\n```\n[/tn]") # XXX invalid html
    assert_parse('<p class="tn"><pre>code</pre></p>', "[tn]\n```\ncode\n```") # XXX invalid html
  end

  def test_urls
    assert_parse('<p>a <a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://test.com">http://test.com</a> b</p>', 'a http://test.com b')
    assert_parse('<p>a <a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="Http://test.com">Http://test.com</a> b</p>', 'a Http://test.com b')
  end

  def test_urls_with_newline
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://test.com">http://test.com</a><br>b</p>', "http://test.com\nb")
  end

  def test_urls_with_paths
    assert_parse('<p>a <a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://test.com/~bob/image.jpg">http://test.com/~bob/image.jpg</a> b</p>', 'a http://test.com/~bob/image.jpg b')
  end

  def test_urls_with_fragment
    assert_parse('<p>a <a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://test.com/home.html#toc">http://test.com/home.html#toc</a> b</p>', 'a http://test.com/home.html#toc b')
  end

  def test_auto_urls
    assert_parse('<p>a <a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://test.com">http://test.com</a>. b</p>', 'a http://test.com. b')
  end

  def test_auto_urls_in_parentheses
    assert_parse('<p>a (<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://test.com">http://test.com</a>) b</p>', 'a (http://test.com) b')
    assert_parse('<p>(at <a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://test.com/1234?page=42)">http://test.com/1234?page=42)</a>. blah</p>', '(at http://test.com/1234?page=42). blah')
  end

  def test_internal_links
    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us">https://danbooru.donmai.us</a></p>', 'https://danbooru.donmai.us', domain: "danbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="https://danbooru.donmai.us">https://danbooru.donmai.us</a></p>', 'https://danbooru.donmai.us', domain: "testbooru.donmai.us")

    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us">https://danbooru.donmai.us</a></p>', 'https://danbooru.donmai.us', domain: "danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us/login">https://danbooru.donmai.us/login</a></p>', 'https://danbooru.donmai.us/login', domain: "danbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="https://danbooru.donmai.us/login">https://danbooru.donmai.us/login</a></p>', 'https://danbooru.donmai.us/login', domain: "testbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="https://danbooru.donmai.us/login">https://danbooru.donmai.us/login</a></p>', 'https://danbooru.donmai.us/login', domain: "")

    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us">https://danbooru.donmai.us</a></p>', '<https://danbooru.donmai.us>', domain: "danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us/login">https://danbooru.donmai.us/login</a></p>', '<https://danbooru.donmai.us/login>', domain: "danbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="https://danbooru.donmai.us/login">https://danbooru.donmai.us/login</a></p>', '<https://danbooru.donmai.us/login>', domain: "testbooru.donmai.us")

    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us">home</a></p>', '"home":https://danbooru.donmai.us', domain: "danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us/login">login</a></p>', '"login":https://danbooru.donmai.us/login', domain: "danbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="https://danbooru.donmai.us/login">login</a></p>', '"login":https://danbooru.donmai.us/login', domain: "testbooru.donmai.us")

    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us">home</a></p>', '"home":[https://danbooru.donmai.us]', domain: "danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us/login">login</a></p>', '"login":[https://danbooru.donmai.us/login]', domain: "danbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="https://danbooru.donmai.us/login">login</a></p>', '"login":[https://danbooru.donmai.us/login]', domain: "testbooru.donmai.us")

    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us">home</a></p>', '[https://danbooru.donmai.us](home)', domain: "danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us/login">login</a></p>', '[https://danbooru.donmai.us/login](login)', domain: "danbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="https://danbooru.donmai.us/login">login</a></p>', '[https://danbooru.donmai.us/login](login)', domain: "testbooru.donmai.us")

    assert_parse('<p><a class="dtext-link" href="https://user:pass@danbooru.donmai.us:80">https://user:pass@danbooru.donmai.us:80</a></p>', 'https://user:pass@danbooru.donmai.us:80', domain: "danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us/posts?tags=simple@house">https://danbooru.donmai.us/posts?tags=simple@house</a></p>', 'https://danbooru.donmai.us/posts?tags=simple@house', domain: "danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us/posts?tags=%s">https://danbooru.donmai.us/posts?tags=%s</a></p>', 'https://danbooru.donmai.us/posts?tags=%s', domain: "danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us/posts?tags=pok%E9mon">https://danbooru.donmai.us/posts?tags=pok%E9mon</a></p>', 'https://danbooru.donmai.us/posts?tags=pok%E9mon', domain: "danbooru.donmai.us")
    assert_parse('<p><a class="dtext-link" href="https://danbooru.donmai.us/posts?tags=foo%00bar">https://danbooru.donmai.us/posts?tags=foo%00bar</a></p>', 'https://danbooru.donmai.us/posts?tags=foo%00bar', domain: "danbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="https:///">https:///</a></p>', 'https:///', domain: "danbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="https://#">https://#</a></p>', 'https://#', domain: "danbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="https://?">https://?</a></p>', '<https://?>', domain: "danbooru.donmai.us")
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="https://:">https://:</a></p>', '<https://:>', domain: "danbooru.donmai.us")
  end

  def test_old_style_links
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com">test</a></p>', '"test":http://test.com')
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="Http://test.com">test</a></p>', '"test":Http://test.com')

    assert_parse('<p><a class="dtext-link" href="#">test</a></p>', '"test":#')
    assert_parse('<p><a class="dtext-link" href="/">test</a></p>', '"test":/')
    assert_parse('<p><a class="dtext-link" href="/x">test</a></p>', '"test":/x')
    assert_parse('<p><a class="dtext-link" href="//">test</a></p>', '"test"://')

    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://example.com">test</a></p>', '"test"://example.com')
  end

  def test_old_style_links_with_inline_tags
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com"><em>test</em></a></p>', '"[i]test[/i]":http://test.com')
  end

  def test_old_style_links_with_nested_links
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com">post #1</a></p>', '"post #1":http://test.com')
  end

  def test_old_style_links_with_special_entities
    assert_parse('<p>&quot;1&quot; <a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://three.com">2 &amp; 3</a></p>', '"1" "2 & 3":http://three.com')
  end

  def test_new_style_links
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com">test</a></p>', '"test":[http://test.com]')
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="Http://test.com">test</a></p>', '"test":[Http://test.com]')

    assert_parse('<p><a class="dtext-link" href="#">test</a></p>', '"test":[#]')
    assert_parse('<p><a class="dtext-link" href="/">test</a></p>', '"test":[/]')
    assert_parse('<p><a class="dtext-link" href="/x">test</a></p>', '"test":[/x]')
    assert_parse('<p><a class="dtext-link" href="//">test</a></p>', '"test":[//]')

    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://example.com">test</a></p>', '"test":[//example.com]')
  end

  def test_new_style_links_with_inline_tags
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com/(parentheses)"><em>test</em></a></p>', '"[i]test[/i]":[http://test.com/(parentheses)]')
  end

  def test_new_style_links_with_nested_links
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com">post #1</a></p>', '"post #1":[http://test.com]')
  end

  def test_new_style_links_with_parentheses
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com/(parentheses)">test</a></p>', '"test":[http://test.com/(parentheses)]')
    assert_parse('<p>(<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com/(parentheses)">test</a>)</p>', '("test":[http://test.com/(parentheses)])')
    assert_parse('<p>[<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com/(parentheses)">test</a>]</p>', '["test":[http://test.com/(parentheses)]]')
  end

  def test_markdown_links
    assert_inline_parse('<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://example.com">test</a>', '[http://example.com](test)')
    assert_inline_parse('<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="Http://example.com">test</a>', '[Http://example.com](test)')
    assert_inline_parse('<em>one</em>(two)', '[i]one[/i](two)')

    assert_inline_parse(CGI.escapeHTML('[blah](test)'), '[blah](test)')
    assert_inline_parse(CGI.escapeHTML('[](test)'), '[](test)')
  end

  def test_html_links
    assert_inline_parse('<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://example.com">test</a>', '<a href="http://example.com">test</a>')
    assert_inline_parse('<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="Http://example.com">test</a>', '<a href="Http://example.com">test</a>')
    assert_inline_parse('<a class="dtext-link" href="/x">a <em>b</em> c</a>', '<a href="/x">a [i]b[/i] c</a>')

    assert_parse('<p><a class="dtext-link" href="#">test</a></p>', '<a href="#">test</a>')
    assert_parse('<p><a class="dtext-link" href="/">test</a></p>', '<a href="/">test</a>')
    assert_parse('<p><a class="dtext-link" href="/x">test</a></p>', '<a href="/x">test</a>')
    assert_parse('<p><a class="dtext-link" href="//">test</a></p>', '<a href="//">test</a>')
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://x">test</a></p>', '<a href="//x">test</a>')
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://evil.com">test</a></p>', '<a href="//evil.com">test</a>')

    assert_inline_parse(CGI.escapeHTML('<a href="">test</a>'), '<a href="">test</a>')
    assert_inline_parse(CGI.escapeHTML('<a id="foo" href="">test</a>'), '<a id="foo" href="">test</a>')
  end

  def test_fragment_only_urls
    assert_parse('<p><a class="dtext-link" href="#toc">test</a></p>', '"test":#toc')
    assert_parse('<p><a class="dtext-link" href="#toc">test</a></p>', '"test":[#toc]')
  end

  def test_auto_url_boundaries
    assert_parse('<p>a （<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://test.com">http://test.com</a>） b</p>', 'a （http://test.com） b')
    assert_parse('<p>a 〜<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://test.com">http://test.com</a>〜 b</p>', 'a 〜http://test.com〜 b')
    assert_parse('<p>a <a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://test.com">http://test.com</a>　 b</p>', 'a http://test.com　 b')
    assert_parse('<p>a <a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://dic.pixiv.net/a/姉ヶ崎寧々">http://dic.pixiv.net/a/姉ヶ崎寧々</a> b</p>', 'a http://dic.pixiv.net/a/姉ヶ崎寧々 b')
  end

  def test_old_style_link_boundaries
    assert_parse('<p>a 「<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com">title</a>」 b</p>', 'a 「"title":http://test.com」 b')
  end

  def test_new_style_link_boundaries
    assert_parse('<p>a 「<a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="http://test.com">title</a>」 b</p>', 'a 「"title":[http://test.com]」 b')
  end

  def test_lists_1
    assert_parse('<ul><li>a</li></ul>', '* a')
    assert_parse('<ul><li>a</li><li>b</li></ul>', "* a\n* b")
    assert_parse('<ul><li>a</li><li>b</li><li>c</li></ul>', "* a\n* b\n* c")

    assert_parse('<ul><li>a</li><li>b</li></ul>', "* a\r\n* b")
    assert_parse('<ul><li>a</li></ul><ul><li>b</li></ul>', "* a\n\n* b")
    assert_parse('<ul><li>a</li><li>b</li><li>c</li></ul>', "* a\r\n* b\r\n* c")

    assert_parse('<ul><li>a</li><ul><li>b</li></ul></ul>', "* a\n** b")
    assert_parse('<ul><li>a</li><ul><li>b</li><ul><li>c</li></ul></ul></ul>', "* a\n** b\n*** c")
    #assert_parse('<ul><ul><ul><li>a</li></ul><li>b</li></ul><li>c</li></ul>', "*** a\n**\n b\n* c")
    assert_parse('<ul><ul><ul><li>a</li></ul></ul><li>b</li></ul>', "*** a\n* b")
    assert_parse('<ul><ul><ul><li>a</li></ul></ul></ul>', "*** a")

    # assert_parse('<ul><li>a</li></ul><p>b</p><ul><li>c</li></ul>', "* a\nb\n* c")
    assert_parse('<ul><li>a<br>b</li><li>c</li></ul>', "* a\nb\n* c") # XXX wrong?

    assert_parse('<p>a<br>b</p><ul><li>c</li><li>d</li></ul>', "a\nb\n* c\n* d")
    assert_parse('<p>a</p><ul><li>b<br>c</li><li>d<br>e</li></ul><p>another one</p>', "a\n* b\nc\n* d\ne\n\nanother one")
    assert_parse('<p>a</p><ul><li>b<br>c</li><ul><li>d<br>e</li></ul></ul><p>another one</p>', "a\n* b\nc\n** d\ne\n\nanother one")

    assert_parse('<ul><li><a class="dtext-link dtext-id-link dtext-post-id-link" href="/posts/1">post #1</a></li></ul>', "* post #1")

    assert_parse('<ul><li><em>a</em></li><li>b</li></ul>', "* [i]a[/i]\n* b")

    # assert_parse('<ul><li><em>a</em></li><li>b</li></ul>', "* [i]a\n* b")
    assert_parse('<ul><li><em>a<li>b</li></em></li></ul>', "* [i]a\n* b") # XXX wrong

    # assert_parse('<p><em>a</em><ul><li>a<li>b</li></li></ul>', "[i]a\n* b\n* c")
    assert_parse('<p><em>a<ul><li>b</li><li>c</li></ul></em></p>', "[i]a\n* b\n* c") # XXX wrong

    # assert_parse('<ul><li></li></ul><h4>See also</h4><ul><li>a</li></ul>', "* h4. See also\n* a")
    assert_parse('<ul><li>h4. See also</li><li>a</li></ul>', "* h4. See also\n* a") # XXX wrong?

    # assert_parse('<ul><li>a</li></ul><h4>See also</h4>', "* a\nh4. See also")
    assert_parse('<ul><li>a<br>h4. See also</li></ul>', "* a\nh4. See also") # XXX wrong

    # assert_parse('<h4><em>See also</em></h4><ul><li>a</li></ul>', "h4. [i]See also\n* a")
    assert_parse('<h4><em>See also</em><ul><li>a</li></ul></h4>', "h4. [i]See also\n* a") # XXX wrong

    # assert_parse('<ul><li><em>a</em></li></ul><h4>See also</h4>', "* [i]a\nh4. See also")
    assert_parse('<ul><li><em>a<br>h4. See also</em></li></ul>', "* [i]a\nh4. See also") # XXX wrong

    assert_parse('<h4>See also</h4><ul><li>a</li></ul>', "h4. See also\n* a")
    assert_parse('<h4>See also</h4><ul><li>a</li><li>h4. External links</li></ul>', "h4. See also\n* a\n* h4. External links")

    # assert_parse('<p>a</p><div class="spoiler"><ul><li>b</li><li>c</li></ul></div><p>d</p>', "a\n[spoilers]\n* b\n* c\n[/spoilers]\nd")
    assert_parse('<p>a<br><span class="spoiler"><ul><li>b</li><li>c</li></ul></span><br>d</p>', "a\n[spoilers]\n* b\n* c\n[/spoilers]\nd") # XXX wrong

    assert_parse('<p>a</p><blockquote><ul><li>b</li><li>c</li></ul></blockquote><p>d</p>', "a\n[quote]\n* b\n* c\n[/quote]\nd")
    assert_parse('<p>a</p><details><summary>Show</summary><div><ul><li>b</li><li>c</li></ul></div></details><p>d</p>', "a\n[expand]\n* b\n* c\n[/expand]\nd")

    assert_parse('<p>a</p><blockquote><ul><li>b</li><li>c</li></ul><p>d</p></blockquote>', "a\n[quote]\n* b\n* c\n\nd")
    assert_parse('<p>a</p><details><summary>Show</summary><div><ul><li>b</li><li>c</li></ul><p>d</p></div></details>', "a\n[expand]\n* b\n* c\n\nd")

    assert_parse('<p>*</p>', "*")
    assert_parse('<p>*a</p>', "*a")
    assert_parse('<p>***</p>', "***")
    assert_parse('<p>*<br>*<br>*</p>', "*\n*\n*")
    assert_parse('<p>* <br>blah</p>', "* \r\nblah")
  end

  def test_inline_tags
    assert_parse('<p><a class="dtext-link dtext-post-search-link" href="/posts?tags=tag">tag</a></p>', "{{tag}}")
    assert_parse('<p>hello <code>tag</code></p>', "hello [code]tag[/code]")
  end

  def test_inline_tags_conjunction
    assert_parse('<p><a class="dtext-link dtext-post-search-link" href="/posts?tags=tag1%20tag2">tag1 tag2</a></p>', "{{tag1 tag2}}")
    assert_parse('<p><a class="dtext-link dtext-post-search-link" href="https://danbooru.donmai.us/posts?tags=tag1%20tag2">tag1 tag2</a></p>', "{{tag1 tag2}}", base_url: "https://danbooru.donmai.us")
  end

  def test_inline_tags_special_entities
    assert_parse('<p><a class="dtext-link dtext-post-search-link" href="/posts?tags=%3C3">&lt;3</a></p>', "{{<3}}")
    assert_parse('<p><a class="dtext-link dtext-post-search-link" href="/posts?tags=%20%22%23%26%2B%3C%3E%3F"> &quot;#&amp;+&lt;&gt;?</a></p>', '{{ "#&+<>?}}')
    assert_parse('<p><a class="dtext-link dtext-post-search-link" href="/posts?tags=%E6%9D%B1%E6%96%B9">東方</a></p>', "{{東方}}")
  end

  def test_extra_newlines
    assert_parse('<p>a</p><p>b</p>', "a\n\n\n\n\n\n\nb\n\n\n\n")

    assert_parse('<p>foo</p>', "foo\n")
    assert_parse('<ul><li>See also</li></ul>', "* See also\n")
    assert_parse('<ul><li>See also</li></ul>', "\n* See also\n")
    assert_parse('<h1>foo</h1>', "h1. foo\n")

    assert_parse('<p>inline <em>foo</em></p>', "inline [i]foo\n")
    assert_parse('<p>inline <span class="spoiler">blah</span></p>', "inline [spoiler]blah\n")
    assert_parse('<p>inline <span class="tn">blah</span></p>', "inline [tn]blah\n")
    assert_parse("<p>inline <code>blah\n</code></p>", "inline [code]blah\n")
    assert_parse("<p>inline blah\n</p>", "inline [nodtext]blah\n")

    assert_parse('<p class="tn">foo</p>', "[tn]foo\n")
    assert_parse("<pre>foo\n</pre>", "[code]foo\n")
    assert_parse("<blockquote><p>foo</p></blockquote>", "[quote]foo\n")
    assert_parse("<details><summary>Show</summary><div><p>foo</p></div></details>", "[expand]foo\n")
    assert_parse("<p>foo\n</p>", "[nodtext]foo\n") # XXX should replace newlines

    assert_parse('<p>[/i]<br>blah</p>', "[/i]\nblah\n")
    assert_parse('<p>[/code]<br>blah</p>', "[/code]\nblah\n")
    assert_parse('<p>[/nodtext]<br>blah</p>', "[/nodtext]\nblah\n")
    assert_parse('<p>[/th]<br>blah</p>', "[/th]\nblah\n")
    assert_parse('<p>[/td]<br>blah</p>', "[/td]\nblah\n")

    assert_parse('<p>[/tn]<br>blah</p>', "[/tn]\nblah\n")
    assert_parse('<p>blah</p>', "[/spoiler]\nblah\n") # XXX wrong
    assert_parse('<p>[/expand]<br>blah</p>', "[/expand]\nblah\n")

    assert_parse("<p>[/quote]<br>blah</p>", "[/quote]\nblah\n")

    assert_parse('<blockquote><ul><li>foo</li><li>bar</li></ul></blockquote>', "[quote]\n* foo\n* bar\n[/quote]")
    assert_parse('<blockquote><p>[/expand]<br>blah</p></blockquote>', "[quote][/expand]\nblah\n")

    assert_parse('<table class="striped"><tr><td><br>foo</td></tr></table>', "\n[table]\n[tr]\n[td]\nfoo\n[/td]\n[/tr]\n[/table]\n") # XXX wrong

    assert_parse('<p class="tn">foo</p>', "[tn]foo\n[/tn]")
    assert_parse('<p class="tn"><br>foo</p>', "[tn]\nfoo\n[/tn]") # XXX wrong
    assert_parse('<p class="tn"><br>foo</p>', "[tn]\nfoo[/tn]") # XXX wrong

    assert_parse('<p>inline <span class="tn">foo</span></p>', "inline [tn]foo\n[/tn]")
    assert_parse('<p>inline <span class="tn">foo</span> bar</p>', "inline [tn]foo\n[/tn] bar") # XXX wrong?
    assert_parse('<p>inline <span class="tn"><br>foo</span> bar</p>', "inline [tn]\nfoo[/tn] bar") # XXX wrong?
    assert_parse('<p>inline <span class="tn"><br>foo</span> bar</p>', "inline [tn]\nfoo\n[/tn] bar") # XXX wrong?
  end

  def test_complex_links_1
    assert_parse("<p><a class=\"dtext-link dtext-wiki-link\" href=\"/wiki_pages/~1\">2 3</a> | <a class=\"dtext-link dtext-wiki-link\" href=\"/wiki_pages/~4\">5 6</a></p>", "[[1|2 3]] | [[4|5 6]]")
  end

  def test_complex_links_2
    assert_parse("<p>Tags <strong>(<a class=\"dtext-link dtext-wiki-link\" href=\"/wiki_pages/howto%3Atag\">Tagging Guidelines</a> | <a class=\"dtext-link dtext-wiki-link\" href=\"/wiki_pages/howto%3Atag_checklist\">Tag Checklist</a> | <a class=\"dtext-link dtext-wiki-link\" href=\"/wiki_pages/tag_groups\">Tag Groups</a>)</strong></p>", "Tags [b]([[howto:tag|Tagging Guidelines]] | [[howto:tag_checklist|Tag Checklist]] | [[Tag Groups]])[/b]")
  end

  def text_note_id_link
    assert_parse('<p><a class="dtext-link dtext-id-link dtext-note-id-link" href="/notes/1234">note #1234</a></p>', "note #1234")
  end

  def test_table
    assert_parse("<table class=\"striped\"><thead><tr><th>header</th></tr></thead><tbody><tr><td><a class=\"dtext-link dtext-id-link dtext-post-id-link\" href=\"/posts/100\">post #100</a></td></tr></tbody></table>", "[table][thead][tr][th]header[/th][/tr][/thead][tbody][tr][td]post #100[/td][/tr][/tbody][/table]")
  end

  def test_table_with_newlines
    assert_parse("<table class=\"striped\"><thead><tr><th>header</th></tr></thead><tbody><tr><td><a class=\"dtext-link dtext-id-link dtext-post-id-link\" href=\"/posts/100\">post #100</a></td></tr></tbody></table>", "[table]\n[thead]\n[tr]\n[th]header[/th][/tr][/thead][tbody][tr][td]post #100[/td][/tr][/tbody][/table]")
  end

  def test_unclosed_th
    assert_parse('<table class="striped"><th>foo</th></table>', "[table][th]foo")
  end

  def test_forum_links
    assert_parse('<p><a class="dtext-link dtext-id-link dtext-forum-topic-id-link" href="/forum_topics/1234?page=4">topic #1234/p4</a></p>', "topic #1234/p4")
  end

  def test_id_links
    assert_parse_id_link("dtext-post-id-link", "/posts/1234", "post #1234")
    assert_parse_id_link("dtext-post-appeal-id-link", "/post_appeals/1234", "appeal #1234")
    assert_parse_id_link("dtext-post-flag-id-link", "/post_flags/1234", "flag #1234")
    assert_parse_id_link("dtext-note-id-link", "/notes/1234", "note #1234")
    assert_parse_id_link("dtext-forum-post-id-link", "/forum_posts/1234", "forum #1234")
    assert_parse_id_link("dtext-forum-topic-id-link", "/forum_topics/1234", "topic #1234")
    assert_parse_id_link("dtext-comment-id-link", "/comments/1234", "comment #1234")
    assert_parse_id_link("dtext-pool-id-link", "/pools/1234", "pool #1234")
    assert_parse_id_link("dtext-user-id-link", "/users/1234", "user #1234")
    assert_parse_id_link("dtext-artist-id-link", "/artists/1234", "artist #1234")
    assert_parse_id_link("dtext-ban-id-link", "/bans/1234", "ban #1234")
    assert_parse_id_link("dtext-tag-alias-id-link", "/tag_aliases/1234", "alias #1234")
    assert_parse_id_link("dtext-tag-implication-id-link", "/tag_implications/1234", "implication #1234")
    assert_parse_id_link("dtext-favorite-group-id-link", "/favorite_groups/1234", "favgroup #1234")
    assert_parse_id_link("dtext-mod-action-id-link", "/mod_actions/1234", "mod action #1234")
    assert_parse_id_link("dtext-user-feedback-id-link", "/user_feedbacks/1234", "feedback #1234")
    assert_parse_id_link("dtext-wiki-page-id-link", "/wiki_pages/1234", "wiki #1234")
    assert_parse_id_link("dtext-moderation-report-id-link", "/moderation_reports/1234", "modreport #1234")
    assert_parse_id_link("dtext-dmail-id-link", "/dmails/1234", "dmail #1234")

    assert_parse_id_link("dtext-github-id-link", "https://github.com/danbooru/danbooru/issues/1234", "issue #1234")
    assert_parse_id_link("dtext-github-pull-id-link", "https://github.com/danbooru/danbooru/pull/1234", "pull #1234")
    assert_parse_id_link("dtext-github-commit-id-link", "https://github.com/danbooru/danbooru/commit/1234", "commit #1234")
    assert_parse_id_link("dtext-artstation-id-link", "https://www.artstation.com/artwork/A1", "artstation #A1")
    assert_parse_id_link("dtext-deviantart-id-link", "https://www.deviantart.com/deviation/1234", "deviantart #1234")
    assert_parse_id_link("dtext-nijie-id-link", "https://nijie.info/view.php?id=1234", "nijie #1234")
    assert_parse_id_link("dtext-pawoo-id-link", "https://pawoo.net/web/statuses/1234", "pawoo #1234")
    assert_parse_id_link("dtext-pixiv-id-link", "https://www.pixiv.net/artworks/1234", "pixiv #1234")
    assert_parse_id_link("dtext-pixiv-id-link", "https://www.pixiv.net/artworks/1234#2", "pixiv #1234/p2")
    assert_parse_id_link("dtext-seiga-id-link", "https://seiga.nicovideo.jp/seiga/im1234", "seiga #1234")
    assert_parse_id_link("dtext-twitter-id-link", "https://twitter.com/i/web/status/1234", "twitter #1234")

    assert_parse_id_link("dtext-yandere-id-link", "https://yande.re/post/show/1234", "yandere #1234")
    assert_parse_id_link("dtext-sankaku-id-link", "https://chan.sankakucomplex.com/post/show/1234", "sankaku #1234")
    assert_parse_id_link("dtext-gelbooru-id-link", "https://gelbooru.com/index.php?page=post&amp;s=view&amp;id=1234", "gelbooru #1234")
  end

  def test_dmail_key_id_link
    assert_parse(%{<p><a class="dtext-link dtext-id-link dtext-dmail-id-link" href="/dmails/1234?key=abc%3D%3D--DEF123">dmail #1234</a></p>}, "dmail #1234/abc==--DEF123")
    assert_parse(%{<p><a class="dtext-link dtext-id-link dtext-dmail-id-link" href="http://danbooru.donmai.us/dmails/1234?key=abc%3D%3D--DEF123">dmail #1234</a></p>}, "dmail #1234/abc==--DEF123", base_url: "http://danbooru.donmai.us")
  end

  def test_boundary_exploit
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="mack" href="/users?name=mack">@mack</a>&lt;</p>', "@mack<")
  end

  def test_expand
    assert_parse("<details><summary>Show</summary><div><p>hello world</p></div></details>", "[expand]hello world[/expand]")
    assert_parse("<details><summary>Show</summary><div><p>hello world</p></div></details>", "<expand>hello world</expand>")
    assert_parse("<details><summary>Show</summary><div><p>hello world</p></div></details>", "<expand>hello world[/expand]")
    assert_parse("<details><summary>Show</summary><div><p>hello world</p></div></details>", "[expand]hello world</expand>")

    assert_parse("<p>inline </p><details><summary>Show</summary><div><p>blah blah</p></div></details>", "inline [expand]blah blah[/expand]")
    assert_parse("<p>inline <em>foo </em></p><details><summary>Show</summary><div><p>blah blah</p></div></details>", "inline [i]foo [expand]blah blah[/expand]")
    assert_parse('<p>inline <span class="spoiler">foo </span></p><details><summary>Show</summary><div><p>blah blah</p></div></details>', "inline [spoiler]foo [expand]blah blah[/expand]")

    assert_parse("<p>inline <em>foo</em></p><details><summary>Show</summary><div><p>blah blah</p></div></details>", "inline [i]foo\n\n[expand]blah blah[/expand]")
    assert_parse('<p>inline <span class="spoiler">foo</span></p><details><summary>Show</summary><div><p>blah blah</p></div></details>', "inline [spoiler]foo\n\n[expand]blah blah[/expand]")

    assert_parse('<details><summary>Show</summary><div><p>test</p></div></details>', "[expand]\ntest\n[/expand] ")
    assert_parse('<details><summary>Show</summary><div><p>test</p></div></details><p>blah</p>', "[expand]\ntest\n[/expand] blah")
    assert_parse('<details><summary>Show</summary><div><p>test</p></div></details><p>blah</p>', "[expand]\ntest\n[/expand] \nblah")
    assert_parse('<details><summary>Show</summary><div><p>test</p></div></details><p>blah</p>', "[expand]\ntest\n[/expand]\nblah")
    assert_parse('<details><summary>Show</summary><div><p>test</p></div></details><p> blah</p>', "[expand]\ntest\n[/expand]\n blah") # XXX should ignore space

    assert_parse("<p>[/expand]</p>", "[/expand]")
    assert_parse("<p>foo [/expand] bar</p>", "foo [/expand] bar")
    assert_parse('<p>test<br>[/expand] blah</p>', "test\n[/expand] blah")
    assert_parse('<p>test<br>[/expand]</p><ul><li>blah</li></ul>', "test\n[/expand]\n* blah")

    assert_parse('<details><summary>Show</summary><div><p>test</p></div></details><h4>See also</h4>', "[expand]\ntest\n[/expand]\nh4. See also")
    assert_parse('<details><summary>Show</summary><div><p>test</p></div></details><div class="spoiler"><p>blah</p></div>', "[expand]\ntest\n[/expand]\n[spoiler]blah[/spoiler]")
  end

  def test_aliased_expand
    assert_parse("<details><summary>hello</summary><div><p>blah blah</p></div></details>", "[expand=hello]blah blah[/expand]")
    assert_parse("<details><summary>hello</summary><div><p>blah blah</p></div></details>", "[expand hello]blah blah[/expand]")
    assert_parse("<details><summary>hello</summary><div><p>blah blah</p></div></details>", "[expand = hello]blah blah[/expand]")
    assert_parse("<details><summary>hello</summary><div><p>blah blah</p></div></details>", "[expand= hello]blah blah[/expand]")
    assert_parse("<details><summary>hello</summary><div><p>blah blah</p></div></details>", "[expand =hello]blah blah[/expand]")

    assert_parse("<details><summary>hello</summary><div><p>blah blah</p></div></details>", "<expand=hello>blah blah</expand>")
    assert_parse("<details><summary>ab]cd</summary><div><p>blah blah</p></div></details>", "<expand=ab]cd>blah blah</expand>")
    assert_parse("<details><summary>ab</summary><div><p>cd&gt;blah blah</p></div></details>", "<expand=ab>cd>blah blah</expand>")

    assert_parse("<details><summary></summary><div><p>blah blah</p></div></details>", "[expand=]blah blah[/expand]")
    assert_parse("<details><summary></summary><div><p>blah blah</p></div></details>", "<expand=>blah blah</expand>")
    assert_parse("<details><summary></summary><div><p>blah blah</p></div></details>", "[expand ]blah blah[/expand]")
    assert_parse("<details><summary></summary><div><p>blah blah</p></div></details>", "[expand= ]blah blah[/expand]")

    assert_parse("<p>[expandhello]blah blah[/expand]</p>", "[expandhello]blah blah[/expand]")
    assert_parse("<p>[expand <br>title]blah blah[/expand]</p>", "[expand \ntitle]blah blah[/expand]")

    assert_parse("<p>inline </p><details><summary>hello</summary><div><p>blah</p></div></details>", "inline [expand=hello]blah[/expand]") # XXX trim space after inline

    assert_parse("<p>inline</p><details><summary>hello</summary><div><p>blah</p></div></details><p>blah</p>", "inline\n[expand=hello]blah[/expand]\nblah")

    # assert_parse("<ul><li>list</li></ul><details><summary>hello</summary><div><p>blah</p></div></details>", "* list\n[expand=hello]blah[/expand]")
    assert_parse("<ul><li>list<br></li></ul><details><summary>hello</summary><div><p>blah</p></div></details>", "* list\n[expand=hello]blah[/expand]") # XXX wrong, trim <br>

    assert_parse("<ul><li>list </li></ul><details><summary>hello</summary><div><p>blah</p></div></details>", "* list [expand=hello]blah[/expand]") # XXX wrong, should ignore in lists

    assert_parse("<h1>foo </h1><details><summary>hello</summary><div><p>blah</p></div></details>", "h1. foo [expand=hello]blah[/expand]") # XXX wrong, should ignore in headers
    assert_parse("<h1>foo</h1><details><summary>hello</summary><div><p>blah</p></div></details>", "h1. foo\n[expand=hello]blah[/expand]")

    assert_parse("<p>inline <em>foo </em></p><details><summary>title</summary><div><p>blah blah</p></div></details>", "inline [i]foo [expand=title]blah blah[/expand]")
    assert_parse('<p>inline <span class="spoiler">foo </span></p><details><summary>title</summary><div><p>blah blah</p></div></details>', "inline [spoiler]foo [expand=title]blah blah[/expand]")
  end

  def test_expand_with_nested_code
    assert_parse("<details><summary>Show</summary><div><pre>hello\n</pre></div></details>", "[expand]\n[code]\nhello\n[/code]\n[/expand]")
  end

  def test_expand_with_nested_list
    assert_parse("<details><summary>Show</summary><div><ul><li>a</li><li>b</li></ul></div></details><p>c</p>", "[expand]\n* a\n* b\n[/expand]\nc")
  end

  def test_hr
    assert_parse("<hr>", "[hr]")
    assert_parse("<hr>", "[HR]")
    assert_parse("<hr>", "<hr>")

    assert_parse("<hr>", " [hr]")
    assert_parse("<hr>", "[hr] ")
    assert_parse("<hr>", " [hr] ")
    assert_parse("<hr>", "\n\n [hr] \n\n")

    assert_parse("<hr><hr><hr>", "[hr]\n\n[hr]\n\n[hr]")
    assert_parse("<hr><hr><hr>", "[hr]\n[hr]\n[hr]")

    assert_parse("<p>foo</p><hr>", "foo\n\n[hr]")
    assert_parse("<hr><p>foo</p>", "[hr]\n\nfoo")

    assert_parse("<p>foo</p><hr>", "foo\n[hr]")
    assert_parse("<hr><p>foo</p>", "[hr]\nfoo")

    assert_parse("<p>x[hr]</p>", "x[hr]")
    assert_parse("<p>[hr]x</p>", "[hr]x")
    assert_parse("<p>foo [hr] bar</p>", "foo [hr] bar")
    assert_parse("<p>[hr][hr]</p>", "[hr][hr]")

    assert_parse("<h1>[hr]</h1>", "h1. [hr]")
    assert_parse("<ul><li>[hr]</li></ul>", "* [hr]")

    assert_parse("<blockquote><hr></blockquote>", "[quote]\n[hr]\n[/quote]")
    assert_parse('<div class="spoiler"><hr></div>', "[spoiler]\n[hr]\n[/spoiler]")
    assert_parse('<p class="tn"><hr></p>', "[tn]\n[hr]\n[/tn]")
    assert_parse("<details><summary>Show</summary><div><hr></div></details>", "[expand]\n[hr]\n[/expand]")
    assert_parse("<pre>[hr]\n</pre>", "[code]\n[hr]\n[/code]") # XXX [code] shouldn't swallow spaces
    assert_parse("<p>[hr]\n</p>", "[nodtext]\n[hr]\n[/nodtext]") # XXX [nodtext] shouldn't swallow spaces
    assert_parse('<table class="striped"></table>', "[table]\n[hr]\n[/table]")

    assert_parse("<h1>foo</h1><hr>", "h1. foo\n[hr]")
    assert_parse("<ul><li>foo</li></ul><hr>", "* foo\n[hr]")

    #assert_parse("<blockquote><hr></blockquote>", "[quote][hr][/quote]") # XXX should this work?
    #assert_parse('<div class="spoiler"><hr></div>', "[spoiler][hr][/spoiler]") # XXX should this work?
    #assert_parse("<details><summary>Show</summary><hr></details>", "[expand][hr][/expand]") # XXX should this work?

    assert_parse("<blockquote><hr></blockquote>", "[quote]\n[hr]\n[/quote]")
    assert_parse('<div class="spoiler"><hr></div>', "[spoiler]\n[hr]\n[/spoiler]")
    assert_parse("<details><summary>Show</summary><div><hr></div></details>", "[expand]\n[hr]\n[/expand]")

    assert_parse('<p>inline <strong></strong></p><hr><p>[/b]</p>', "inline [b]\n[hr]\n[/b]")
    assert_parse('<p>inline <span class="tn"></span></p><hr><p>[/tn]</p>', "inline [tn]\n[hr]\n[/tn]")

    # assert_parse('<p>inline <span class="spoiler"></span></p><hr><p>[/spoiler]</p>', "inline [spoiler]\n[hr]\n[/spoiler]")
    assert_parse('<p>inline <span class="spoiler"></span></p><hr>', "inline [spoiler]\n[hr]\n[/spoiler]") # XXX wrong

    #assert_parse('<p class="tn"><hr></p>', "[tn][hr][/tn]") # XXX shouldn't work
  end

  def test_inline_mode
    assert_equal("hello", parse_inline("hello").strip)
  end

  def test_old_asterisks
    assert_parse("<p>hello *world* neutral</p>", "hello *world* neutral")
  end

  def test_utf8_mentions
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="葉月" href="/users?name=%E8%91%89%E6%9C%88">@葉月</a></p>', "@葉月")
    assert_parse('<p>Hello <a class="dtext-link dtext-user-mention-link" data-user-name="葉月" href="/users?name=%E8%91%89%E6%9C%88">@葉月</a> and <a class="dtext-link dtext-user-mention-link" data-user-name="Alice" href="/users?name=Alice">@Alice</a></p>', "Hello @葉月 and @Alice")
    assert_parse('<p>Should not parse 葉月@葉月</p>', "Should not parse 葉月@葉月")
  end

  def test_mention_boundaries
    assert_parse('<p>「hi <a class="dtext-link dtext-user-mention-link" data-user-name="葉月" href="/users?name=%E8%91%89%E6%9C%88">@葉月</a>」</p>', "「hi @葉月」")
  end

  def test_delimited_mentions
    assert_parse('<p>(blah <a class="dtext-link dtext-user-mention-link" data-user-name="evazion" href="/users?name=evazion">@evazion</a>).</p>', "(blah <@evazion>).")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="葉月" href="/users?name=%E8%91%89%E6%9C%88">@葉月</a></p>', "<@葉月>")

    # assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="nwf_renim" href="/users?name=nwf_renim">@NWF Renim</a></p>', "<@NWF Renim>")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="NWF Renim" href="/users?name=NWF%20Renim">@NWF Renim</a></p>', "<@NWF Renim>") # XXX should normalize to nwf_renim for href

    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="_evazion" href="/users?name=_evazion">@_evazion</a></p>', "<@_evazion>")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="evazion_" href="/users?name=evazion_">@evazion_</a></p>', "<@evazion_>")
    assert_parse('<p><a class="dtext-link dtext-user-mention-link" data-user-name="evazion" href="/users?name=evazion">@evazion</a>blah&gt;</p>', "<@evazion>blah>")

    assert_parse('<p>&lt;@ evazion&gt;</p>', "<@ evazion>")
    assert_parse('<p>&lt;@<br>evazion&gt;</p>', "<@\nevazion>")
    assert_parse('<p>&lt;@eva<br>zion&gt;</p>', "<@eva\nzion>")
  end

  def test_utf8_links
    assert_parse('<p><a class="dtext-link" href="/posts?tags=approver:葉月">7893</a></p>', '"7893":/posts?tags=approver:葉月')
    assert_parse('<p><a class="dtext-link" href="/posts?tags=approver:葉月">7893</a></p>', '"7893":[/posts?tags=approver:葉月]')
    assert_parse('<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="http://danbooru.donmai.us/posts?tags=approver:葉月">http://danbooru.donmai.us/posts?tags=approver:葉月</a></p>', 'http://danbooru.donmai.us/posts?tags=approver:葉月')
    assert_parse('<p><a class="dtext-link dtext-wiki-link" href="/wiki_pages/full_metal_panic%21_%CE%A3">Full Metal Panic! Σ</a></p>', '[[Full Metal Panic! Σ]]')
    assert_parse(%{<p><a class="dtext-link dtext-wiki-link" href="/wiki_pages/%C2%97">\u0097</a></p>}, "[[\u0097]]")
    assert_parse(%{<p><a rel="external nofollow noreferrer" class="dtext-link dtext-external-link dtext-named-external-link" href="https://www.example.com/\u0097">\u0097</a></p>}, %{"\u0097":https://www.example.com/\u0097})
  end

  def test_delimited_links
    dtext = '(blah <https://en.wikipedia.org/wiki/Orange_(fruit)>).'
    html = '<p>(blah <a rel="external nofollow noreferrer" class="dtext-link dtext-external-link" href="https://en.wikipedia.org/wiki/Orange_(fruit)">https://en.wikipedia.org/wiki/Orange_(fruit)</a>).</p>'
    assert_parse(html, dtext)
  end

  def test_nodtext
    assert_parse('<p>[b]not bold[/b]</p><p> <strong>bold</strong></p>', "[nodtext][b]not bold[/b][/nodtext] [b]bold[/b]")
    assert_parse('<p>[b]not bold[/b]</p><p><strong>hello</strong></p>', "[nodtext][b]not bold[/b][/nodtext]\n\n[b]hello[/b]")
    assert_parse('<p> [b]not bold[/b]</p>', " [nodtext][b]not bold[/b][/nodtext]")
    assert_parse('<p>[b]not bold</p>', "[nodtext][b]not bold")
    assert_parse('<h1>[b]not bold</h1>', "h1. [nodtext][b]not bold")
    assert_parse('<ul><li>[b]not bold</li></ul>', "* [nodtext][b]not bold")
    assert_parse('<div class="spoiler"><p>[b]not bold</p></div>', "[spoiler][nodtext][b]not bold")
    assert_parse('<p class="tn">[b]not bold</p>', "[tn][nodtext][b]not bold")
    assert_parse('<blockquote><p>[b]not bold</p></blockquote>', "[quote][nodtext][b]not bold")
    assert_parse('<p>foo  bar</p>', "foo [nodtext] bar")
    assert_parse('<p>foo bar</p>', "foo [nodtext]bar[/nodtext]")
    assert_parse('<p></p>', "[nodtext]")
    assert_parse('<p></p>', "[nodtext][/nodtext]")
    assert_parse('<p>[/nodtext]</p>', "[/nodtext]")

    assert_parse('', "[nodtext]", inline: true)
    assert_parse('', "[nodtext][/nodtext]", inline: true)
  end

  def test_stray_closing_tags
    assert_parse('<p>inline &lt;/b&gt;</p>', 'inline </b>')
    assert_parse('<p>inline &lt;/i&gt;</p>', 'inline </i>')
    assert_parse('<p>inline &lt;/u&gt;</p>', 'inline </u>')
    assert_parse('<p>inline &lt;/s&gt;</p>', 'inline </s>')
    assert_parse('<p>inline &lt;/code&gt;</p>', 'inline </code>')
    assert_parse('<p>inline &lt;/nodtext&gt;</p>', 'inline </nodtext>')
    assert_parse('<p>inline &lt;/table&gt;</p>', 'inline </table>')
    assert_parse('<p>inline &lt;/thead&gt;</p>', 'inline </thead>')
    assert_parse('<p>inline &lt;/tbody&gt;</p>', 'inline </tbody>')
    assert_parse('<p>inline &lt;/tr&gt;</p>', 'inline </tr>')
    assert_parse('<p>inline &lt;/th&gt;</p>', 'inline </th>')
    assert_parse('<p>inline &lt;/td&gt;</p>', 'inline </td>')

    # assert_parse('<p>inline &lt;/spoiler&gt;</p>', 'inline </spoiler>')
    # assert_parse('<p>inline &lt;/expand&gt;</p>', 'inline </expand>')
    # assert_parse('<p>inline &lt;/quote&gt;</p>', 'inline </quote>')
    assert_parse('<p>inline &lt;/tn&gt;</p>', 'inline </tn>')
    assert_parse('<p>inline </p>&lt;/spoiler&gt;', 'inline </spoiler>') # XXX wrong
    assert_parse('<p>inline &lt;/expand&gt;</p>', 'inline </expand>')
    assert_parse('<p>inline &lt;/quote&gt;</p>', 'inline </quote>')

    # assert_parse('<p>&lt;/spoiler&gt;</p>', '</spoiler>')
    # assert_parse('<p>&lt;/expand&gt;</p>', '</expand>')
    assert_parse('<p>&lt;/quote&gt;</p>', '</quote>')
    assert_parse('<p>&lt;/tn&gt;</p>', '</tn>')
    assert_parse('', '</spoiler>') # XXX wrong
    assert_parse('<p>&lt;/expand&gt;</p>', '</expand>')
    assert_parse('<p>&lt;/quote&gt;</p>', '</quote>')

    assert_parse('<p>&lt;/b&gt;</p>', '</b>')
    assert_parse('<p>&lt;/i&gt;</p>', '</i>')
    assert_parse('<p>&lt;/u&gt;</p>', '</u>')
    assert_parse('<p>&lt;/s&gt;</p>', '</s>')
    assert_parse('<p>&lt;/code&gt;</p>', '</code>')
    assert_parse('<p>&lt;/nodtext&gt;</p>', '</nodtext>')
    assert_parse('<p>&lt;/table&gt;</p>', '</table>')
    assert_parse('<p>&lt;/thead&gt;</p>', '</thead>')
    assert_parse('<p>&lt;/tbody&gt;</p>', '</tbody>')
    assert_parse('<p>&lt;/tr&gt;</p>', '</tr>')
    assert_parse('<p>&lt;/th&gt;</p>', '</th>')
    assert_parse('<p>&lt;/td&gt;</p>', '</td>')
  end

  def test_mismatched_tags
    assert_parse('<p>inline <strong>foo[/i]</strong></p>', 'inline [b]foo[/i]')
    assert_parse('<p>inline <strong><em>foo[/b]</em></strong></p>', 'inline [b][i]foo[/b][/i]')

    # assert_parse('<div class="spoiler"><blockquote><p>foo</p></blockquote></div>', '[spoiler]\n[quote]\nfoo\n[/spoiler][/quote]')
  end

  def test_stack_depth_limit
    assert_raises(DText::Error) { parse("* foo\n" * 513) }
  end

  def test_null_bytes
    assert_raises(DText::Error) { parse("foo\0bar") }
  end

  def test_wiki_link_xss
    assert_raises(DText::Error) do
      parse("[[\xFA<script \xFA>alert(42); //\xFA</script \xFA>]]")
    end
  end

  def test_mention_xss
    assert_raises(DText::Error) do
      parse("@user\xF4<b>xss\xFA</b>")
    end
  end

  def test_url_xss
    assert_raises(DText::Error) do
      parse(%("url":/page\xF4">x\xFA<b>xss\xFA</b>))
    end
  end
end
