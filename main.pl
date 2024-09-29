:- use_module(library(lists)).
:- use_module(library(format)).
:- use_module(library(files)).
:- use_module(library(pio)).
:- use_module(library(dcgs)).
:- use_module(library(debug)).
:- use_module(library(time)).
:- use_module(library(lambda)).

:- use_module(teruel/teruel).

:- use_module(content/authors).
:- use_module(content/posts).

:- initialization(main).

main :-
    portray_clause(prologhub(version(1, 0, 0), author("Adrián Arroyo Calle"))),
    make_directory("output"),
    render_index,
    render_posts,
    render_tags,
    render_archive,
    copy_static,
    render_rss,
    halt.

render_posts :-
    findall(Slug, post(Slug, _, _, _, _, _, _), Slugs),
    maplist(render_post, Slugs).

render_post(Slug) :-
    post(Slug, Title, _Intro, html(ContentLocalPath), Date, Tags, AuthorId),
    path_segments(ContentPath, ["content", ContentLocalPath]),
    phrase_from_file(seq(ContentHtml), ContentPath),
    phrase(format_time("%Y-%m-%d %H:%M:%S", T), Date),
    phrase(format_time("%Y-%m-%d", T), DateStr),
    portray_clause(rendering_post(Slug)),
    maplist(atom_chars, Tags, TagsCs),
    author(AuthorId, Author),
    render("templates/post.html", [
	       "title"-Title,
	       "author"-Author,
	       "content"-ContentHtml,
	       "date"-DateStr,
	       "tags"-TagsCs], Output),
    path_segments(PostPath, ["output", Slug]),
    make_directory(PostPath),
    path_segments(OutputPath, ["output", Slug, "index.html"]),
    phrase_to_file(seq(Output), OutputPath).

render_tags :-
    path_segments(TagPath, ["output", "tag"]),
    make_directory(TagPath),
    findall(Tag, (
		post(_, _, _, _, _, Tags, _),
		member(Tag, Tags)), AllTags),
    sort(AllTags, Tags),
    maplist(render_tag, Tags).

render_tag(Tag) :-
    portray_clause(rendering_tag(Tag)),
    findall(Date-["slug"-Slug, "title"-Title, "date"-DateStr], (
		post(Slug, Title, _Intro, _Content, Date, Tags, _Author),
		member(Tag, Tags),
		phrase(format_time("%Y-%m-%d %H:%M:%S", T), Date),
		phrase(format_time("%Y-%m-%d", T), DateStr)		
	    ), Posts),
    keysort(Posts, SortedPosts1),
    reverse(SortedPosts1, SortedPosts),
    maplist(\X1^X2^(X1 = _-X2), SortedPosts, TagPosts),
    atom_chars(Tag, TagCs),
    render("templates/archive.html", ["tag"-TagCs, "posts"-TagPosts], Output),
    path_segments(TagPath, ["output", "tag", TagCs]),
    make_directory(TagPath),
    path_segments(OutputPath, ["output", "tag", TagCs, "index.html"]),
    phrase_to_file(seq(Output), OutputPath).
    

render_archive :-
    portray_clause(rendering_archive),
    findall(Date-["slug"-Slug, "title"-Title, "date"-DateStr], (
		post(Slug, Title, _Intro, _Content, Date, _Tags, _Author),
		phrase(format_time("%Y-%m-%d %H:%M:%S", T), Date),
		phrase(format_time("%Y-%m-%d", T), DateStr)		
	    ), Posts),
    keysort(Posts, SortedPosts1),
    reverse(SortedPosts1, SortedPosts),
    maplist(\X1^X2^(X1 = _-X2), SortedPosts, ArchivePosts),
    render("templates/archive.html", ["tag"-"_", "posts"-ArchivePosts], Output),
    path_segments(ArchivePath, ["output", "archive"]),
    make_directory(ArchivePath),
    path_segments(OutputPath, ["output", "archive", "index.html"]),
    phrase_to_file(seq(Output), OutputPath).
    

render_index :-
    portray_clause(rendering_index),
    findall(Date-Slug,post(Slug, _Title, _Intro, _Content, Date, _Tags, _Author), Posts),
    keysort(Posts, SortedPosts1),
    reverse(SortedPosts1, SortedPosts),
    length(IndexPosts, 5),
    append(IndexPosts, _, SortedPosts),
    maplist(\X1^X2^(X1 = _-X2), IndexPosts, IndexPostsSlugs),    
    maplist(post_index, IndexPostsSlugs, RenderPosts),
    render("templates/index.html", ["posts"-RenderPosts], Output),
    path_segments(Path, ["output", "index.html"]),
    phrase_to_file(seq(Output), Path).

post_index(Slug, ["slug"-Slug, "title"-Title, "date"-DateStr, "intro"-Intro]) :-
    post(Slug, Title, html(IntroLocalPath), _Content, Date, _Tags, _Author),
    path_segments(IntroPath, ["content", IntroLocalPath]),
    phrase_from_file(seq(Intro), IntroPath),
    phrase(format_time("%Y-%m-%d %H:%M:%S", T), Date),
    phrase(format_time("%Y-%m-%d", T), DateStr).    

copy_static :-
    path_segments(Path, ["output", "static"]),
    make_directory(Path),    
    directory_files("static", StaticFiles),
    maplist(copy_single_static, StaticFiles).

copy_single_static(StaticFile) :-
    portray_clause(copy_file(StaticFile)),
    path_segments(Origin, ["static", StaticFile]),
    path_segments(Destination, ["output", "static", StaticFile]),
    file_copy(Origin, Destination).

render_rss :-
    portray_clause(rendering_rss),
    findall(Date-Slug, post(Slug, _Title, _Intro, _Content, Date, _Tags, _Author), Posts),
    keysort(Posts, SortedPosts1),
    reverse(SortedPosts1, SortedPosts),
    length(IndexPosts, 5),
    append(IndexPosts, _, SortedPosts),
    maplist(\X1^X2^(X1 = _-X2), IndexPosts, IndexPostsSlugs),    
    maplist(post_rss, IndexPostsSlugs, RenderPosts),
    render("templates/rss.xml", ["posts"-RenderPosts], Output),
    path_segments(Path, ["output", "rss.xml"]),
    phrase_to_file(seq(Output), Path).    

post_rss(Slug, ["slug"-Slug, "title"-Title, "content"-Content, "date_rfc822"-DateStr]) :-
    post(Slug, Title, _Intro, html(ContentLocalPath), Date, _Tags, _Author),
    path_segments(ContentPath, ["content", ContentLocalPath]),
    phrase_from_file(seq(Content), ContentPath),
    phrase(format_time("%Y-%m-%d %H:%M:%S", T), Date),
    date_month(T),
    phrase(format_time("%d %b %Y %H:%M:00 UT", T), DateStr).    
    
date_month(T) :-
    member(m="01", T),
    member(b="Jan", T).
date_month(T) :-
    member(m="02", T),
    member(b="Feb", T).
date_month(T) :-
    member(m="03", T),
    member(b="Mar", T).
date_month(T) :-
    member(m="04", T),
    member(b="Apr", T).
date_month(T) :-
    member(m="05", T),
    member(b="May", T).
date_month(T) :-
    member(m="06", T),
    member(b="Jun", T).
date_month(T) :-
    member(m="07", T),
    member(b="Jul", T).
date_month(T) :-
    member(m="08", T),
    member(b="Aug", T).
date_month(T) :-
    member(m="09", T),
    member(b="Sep", T).
date_month(T) :-
    member(m="10", T),
    member(b="Oct", T).
date_month(T) :-
    member(m="11", T),
    member(b="Nov", T).
date_month(T) :-
    member(m="12", T),
    member(b="Dec", T).
