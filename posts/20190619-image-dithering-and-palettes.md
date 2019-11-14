Image dithering and palettes
============================
2019-06-19

A while ago, I decided I wanted to learn more about dithering. While it's not
as necessary today as it was 20-30 years ago, it's still an interesting
technique[^1]. And what better way to learn than to do it yourself?

I wrote a Python library that implements several well-known dithering
algorithms, starting from the basic threshold algorithm (which barely counts as
dithering in my opinion), to error diffusion algorithms such as the famous
Floyd-Steinberg method.

Many of these methods were originally used to print images using only black ink
while still retaining gradients and detail of the source image. On a screen
this translates to quantizing pixels in the source image to either black or
white. Having only one color palette is boring, though, especially if it's
essentially a 1-bit grayscale palette. So, I also implemented several
well-known color palettes, such as EGA and 6-bit websafe.

In this post I briefly talk about the various methods. The palettes going into
it are of interest too, and have some history and quirks to them. I will save
those for another post to keep this from getting too long. If you want to play
with the library, it's available on GitHub
[here](https://github.com/ahota/dither).

## Dithering methods

At the heart of dithering, we are simply taking an input pixel value and
quantizing it to a new output pixel value in a smaller range. I'm assuming all
my incoming pixels have a value in [0, 255]. We can then say that we want to
quantize to _n_ levels, which effectively simulates an log2(_n_)-bit display of
an 8-bit source image.

If we iterate through each pixel of the image and perform this quantization, we
are performing the basic _threshold_ method. Here's an example of threshold
with 2 levels:

<ul class="wp-block-gallery aligncenter columns-2 is-cropped">
<li class="blocks-gallery-item">
<figure>
<img src="https://ahotanet.files.wordpress.com/2019/05/taj_mahal.jpg" alt="" data-id="84" data-link="https://ahota.net/taj_mahal/" class="wp-image-84" />
<figcaption>
Original Taj Mahal image</figcaption>
</figure>
</li>
<li class="blocks-gallery-item">
<figure>
<img src="https://ahotanet.files.wordpress.com/2019/05/taj_mahal_1.jpg" alt="" data-id="85" data-link="https://ahota.net/taj_mahal_1/" class="wp-image-85" />
<figcaption>
1-bit (2-level) threshold dithered Taj Mahal</figcaption>
</figure>
</li>
</ul>

While this method solves the problem of using a smaller output color space, it
isn't good for detail, and definitely bad for gradients. But it does the job,
and the image is recognizable.

### Ordered dithering

Quantization allows us to take a high resolution input and express it in terms
of a lower resolution range. The problem with doing this is that you are losing
information; i.e. each quantization has a certain amount of error. The
threshold method above has a huge amount of error when the number of output
values is low. A pixel that should be mid-gray with value 127 can be quantized
all the way down to 0.

_Ordered dithering_ tries to mitigate this by applying a threshold map to the
image. This allows the error to be spread across a region of the image as
opposed to be centralized to each pixel. We can tile this threshold map across
our image and quantize each pixel based on its corresponding map value.

For example, we can use a 4x4 threshold map. The values within this map would
be 0-15 (16 values because it's a 4x4 map), scaled by 1/16. That is, our map
simply contains 16 values in [0, 1]. Sound familiar? We could just as easily
use 16 values in [0, 255], but most documentation and image processing methods
tend to work on floating point values in [0, 1]. 

The arrangement of values in the map is what differentiates ordered dithering
techniques from one another. Bayer 4x4 is a common one that produces this
familiar cross-hatching pattern:

<ul class="wp-block-gallery aligncenter columns-2 is-cropped"><li class="blocks-gallery-item"><figure><img src="https://ahotanet.files.wordpress.com/2019/05/taj_mahal.jpg?w=200" alt="" data-id="84" class="wp-image-84" /><figcaption> _Original Taj Mahal image_</figcaption></figure></li><li class="blocks-gallery-item"><figure><img src="https://ahotanet.files.wordpress.com/2019/05/taj_mahal_1_od.jpg?w=200" data-id="88" class="wp-image-88" /><figcaption>Bayer 4x4 1-bit (2-level) dithered Taj Mahal</figcaption></figure></li></ul>

This is much better for gradients and detail, though we're still blowing out
the sky due to the low output color depth. That's what you get for having a
monochrome screen, though (well, not really. There could be some gamma
correction performed on the image before dithering to bring the sky values down
to a more manageable range).

### Error diffusion

Ordered dithering spreads quantization error out within a tile of the image. It
does this with a fixed threshold map, which leads to repeating visual
artifacts.

_Error diffusion_, on the other hand, takes the error from one pixel and
propagates it forward in the image. This spreads error throughout the entire
image, resulting in much nicer gradients without any repeating artifacts. The
idea is that, as we iterate over pixels in the image, we take the error of our
current pixel after quantizing, and apply it partially to some neighboring
pixels.

What differentiates different error diffusion techniques is simply the weight
of partial error propagation and the neighbors to which partial error is
applied. The popular Floyd-Steinberg method applies partial error to the next
neighbor to the right, and the three neighbors below, and creates this
stippling effect:

<ul class="wp-block-gallery aligncenter columns-2 is-cropped"><li class="blocks-gallery-item"><figure><img src="https://ahotanet.files.wordpress.com/2019/05/taj_mahal.jpg?w=200" alt="" data-id="84" class="wp-image-84" /><figcaption> _Original Taj Mahal image_</figcaption></figure></li><li class="blocks-gallery-item"><figure><img src="https://ahotanet.files.wordpress.com/2019/05/taj_mahal_1_ed.jpg?w=200" data-id="91" class="wp-image-91" /><figcaption>Floyd-Steinberg 1-bit (2-level) dithered Taj Mahal</figcaption></figure></li></ul>

Look at all those details! Those gradients! The image is quite recognizable and
_both_ the reflection and sky are visible. By pushing the error around the
image, we can circumvent high-brightness and low-contrast areas getting washed
out.

###### Categories

* Programming
    * Python
* Image-processing

[^1]: (although websites like [Low Tech
Magazine](https://solar.lowtechmagazine.com/) have found a great use for it in
modern times)
