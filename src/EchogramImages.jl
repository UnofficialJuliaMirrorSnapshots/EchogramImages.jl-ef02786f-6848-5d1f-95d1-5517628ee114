module EchogramImages

using Images
using EchogramColorSchemes
using ColorSchemes

export imagesc, mat2gray, equalizedbins, quantize


"""
    imagesc(A;
             vmin = nothing,
             vmax = nothing,
             cmap= nothing,
             size=(480,640))

A is any numeric array

cmap can be a list of Colors or come from EchogramColorSchemes.jl,
ColorSchemes.jl or PerceptualColourMaps.jl. The default `nothing`
currently means use EK500 colours.

Set size = nothing for full resolution.

vmin and vmax are minimum and maximum values.


"""
function imagesc(A::AbstractArray;
                  vmin = nothing,
                  vmax = nothing,
                  cmap= nothing,
                  size=(480,640))


    if cmap == nothing
        cmap = addwhite(EK500)
    end

    if isa(cmap, ColorScheme)
        cmap = cmap.colors
    end
    
    if size != nothing
        A = imresize(A, size)
    end

    if vmin == nothing
        vmin = minimum(A[.!isnan.(A)])
    end

    if vmax == nothing
        vmax = maximum(A[.!isnan.(A)])
    end

    vmin = float(vmin)
    vmax = float(vmax)

    n = length(cmap)

    g = x -> (clamp(isnan(x) ? vmin : x, vmin, vmax) - vmin) / (vmax - vmin)
    #f = s->clamp(round(Int, (n-1)*g(s))+1, 1, n)
    f = s->cmap[trunc(Int, (n-1)*g(s)) + 1]

    f.(A)

end


"""
    mat2gray(A; amin=nothing, amax=nothing)

Convert matrix `A` to grayscale with pixel values in the range 0.0
(black) to 1.0 (white).

NB Intentionally, NaNs get replaced by 0.0 to facilitate the use of
the wider Julia Images ecosystem.

"""
function mat2gray(A; amin=nothing, amax=nothing)

    B = A[.!isnan.(A)]
    
    if amin == nothing
        amin = minimum(B)
    end
    if amax == nothing
        amax = maximum(B)
    end
    f = scaleminmax(amin, amax)
    C = f.(A)
    C[isnan.(C)] .= 0.0
    return C
end


"""
    equalizedbins(A; nbins = 256, amin=nothing, amax=nothing)

Using histogram equalisation, return the bin edges (the cut off
points) that would allow `A` to be quantized into `nbins`.

"""
function equalizedbins(A; nbins = 256, amin=nothing, amax=nothing)
    a = sort(vec(A))
    if amin != nothing
        filter!(x-> x>amin , a)
        # Reserve a bin for everything below minA
        nbins = nbins -1
    end
    if amax != nothing
        filter!(x-> x<amax , a)
        # Reserve a bin for everything above maxA
        nbins = nbins -1
    end

    # Equalise bin spacing
    d = length(a) / nbins
    r = [a[ceil(Int,i)] for i in d:d:d*(nbins-1)]
    
    if amin != nothing
        # if specified, minA is the first bin dimension
        r = vcat([amin],r)
    end
    if amax != nothing
        # if specified, maxA is the last bin dimension
        r = vcat(r, [amax])
    end
    return r
        
end

"""

    quantize(A, edges)

Quantise the 2D array`A` into `length(edges)` levels where `edges` is
the list of bin cut-off points.

Quantization, in mathematics and digital signal processing, is the
process of mapping input values from a large set (often a continuous
set) to output values in a (countable) smaller set, often with a
finite number of elements.

"""
function quantize(A, edges)
    m,n = size(A)
    if length(edges) < 256
        B= Matrix{UInt8}(undef,m,n)
    else
        B= Matrix(undef,m,n)
    end
    B .= 0
    for i in 1:length(edges)
        B[A .> edges[i]] .= i
    end
    return B
end


end # module
