# Live Splits
## Credits
Thank you to [ArEyeses](https://github.com/ArEyeses79?tab=repositories) for allowing me to use some code snippets from the [Extended Medals](https://github.com/ArEyeses79/tm-ultimate-medals-extended) Plugin to get the current PB time.

## Disclaimer
This plugin is not very performant by nature. Despite my best optimisation efforts, this could slow down your game. Consider adjusting settings or not using at all.

## Introduction
This plugin allows you to get the live splits for any ghost. 

## Settings
### Gap Algorithms
There are three currently availible algorithms to get the gap to the ghost. Linear, Modified Linear and Estimation.

**LINEAR** is the slowest algorithm of all. It uses a simple linear search. This allows for the most accurate live gap but is more likely to wrongly estimate the gap if the track often crosses over. This runs worse on longer tracks.

**MODIFIED LINEAR** is a faster alternative to linear. This is a uses a linear search but increments by larger amounts then refines afters. This is a performant yet accurate algorithm. This can also reduce the likelihood of miscalculations. Like linear, this also runs badly on longer tracks.

**ESTIMATION** uses your previous gap and a range to estimate where you might currently be. This is the most performant option at the expense of accuracy. This makes use of some aspects of MODIFIED LINEAR for better performance. Longer tracks will not affect the performance here. However, if a miscalculation is made, the algorithm may not be able to recover its state.

So, which should you choose? If you want super accurate gaps on short tracks and have a powerful computer, use LINEAR. If you want accurate gaps on moderate length tracks or have a lower power computer, use MODIFIED LINEAR. If you are playing tracks that do not cross or that are very long or you have a very low power computer, use ESTIMATION. 

### Frame Timings
In this plugin, there are two current frame timing options. Log rate and gap rate.

**LOG RATE** determines how many frames should be waited before getting the next position log. Increase this value to increase performance but reduce accuracy. There is a balance that can be met so don't be afraid to increase this.

**GAP RATE** determines how many frames should be waited before calculating the gaps. This can compensate for issues of constantly calculating the gap. This can also allow you to have more logs without affecting performance. Increase this value to increase performance but reduce the rate of the live gap.