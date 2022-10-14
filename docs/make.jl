using WGSLTypes
using Documenter

DocMeta.setdocmeta!(WGSLTypes, :DocTestSetup, :(using WGSLTypes); recursive=true)

makedocs(;
    modules=[WGSLTypes],
    authors="arhik <arhik23@gmail.com>",
    repo="https://github.com/arhik/WGSLTypes.jl/blob/{commit}{path}#{line}",
    sitename="WGSLTypes.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://arhik.github.io/WGSLTypes.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/arhik/WGSLTypes.jl",
    devbranch="main",
)
