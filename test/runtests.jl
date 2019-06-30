#!/usr/bin/env julia

using EchogramImages
using Test

a = rand(100,100)
img = imagesc(a)
m,n = size(img)
@test m == 480
@test n == 640
