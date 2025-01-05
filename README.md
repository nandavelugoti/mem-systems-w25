ECE 4/599
=======

This is the [website][mem-systems-site-w25] for a new grad course at OSU on modern memory systems.
It uses [Zola][].

[zola]: https://www.getzola.org


Adding Blog Posts
-----------------

To add a blog post (which you must do for paper discussions and project reports), use a [pull request][pr].

You'll want to create a text file in the `content/blog/` directory with your new post.
Use a filename like `YYYY-MM-DD-title.md`, where the date is the discussion day or the project deadline and the title is up to you.
Include Zola-style "[TOML][] front matter" at the top, which looks like this:

    +++
    title = "Welcome to ECE 4/599!"
    [extra]
    bio = """
      [Kyle Hale](https://www.halek.co/) is an associate professor of computer science. 
    """
    [[extra.authors]]
    name = "Kyle Hale"
    link = "https://www.halek.co/"  # Links are optional.
    [[extra.authors]]
    name = "Ken Thompson"
    +++

List all the authors of your post.
Include a link to your homepage if you have one, but it's optional.
Also write a short bio for yourselves (using [Markdown][]), which will appear at the bottom of the post.
Then, the rest of the text file is the Markdown text of your blog post.

If you want to use math in your blog post, put `latex = true` in your `[extra]` section to enable [KaTeX][]. Then you can use `$\pi$` for inline math and `\[ e^{i\pi} + 1 = 0 \]` for display math.

To include images or other resources in your post, make your post into a directory.
That is, make a new directory called `YYYY-MM-DD-title` inside `content/blog/`.
Then, put your text in a file called `index.md` inside that.
Put your images in the same directory and refer to them with relative paths.
See [the Zola docs on assets][zola-assets] for more details.

You can preview your writing with any Markdown renderer.
To see what it will look like when published, [install Zola][zola-install] and type `zola serve` to preview the entire site.

[pr]: https://help.github.com/en/articles/about-pull-requests
[toml]: https://github.com/toml-lang/toml
[markdown]: https://daringfireball.net/projects/markdown/
[zola-install]: https://www.getzola.org/documentation/getting-started/installation/
[zola-assets]: https://www.getzola.org/documentation/content/overview/#assets-colocation
[katex]: https://katex.org

Acknowledgements
================
This site borrows heavily from Adrian Sampson's [compilers course](https://www.cs.cornell.edu/courses/cs6120/2023fa/) at Cornell.
