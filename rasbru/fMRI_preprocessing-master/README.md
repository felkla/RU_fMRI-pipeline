# fMRI Preprocessing Pipeline

This repository contains code to preprocess fMRI data.

## Getting Started

The code requires [BIDS](http://bids.neuroimaging.io) formatted data. Preprocessing steps include realignment, slicetiming correction, normalization, estimation of noise components and smoothing. We have two main files:

* runPreprocessing: This runs the specified preprocessing pipeline
* prepobj: Preprocessing class definition file

The code also contains a file for running a simple GLM + contrasts: 

* runGLM: This script runs the GLM for either the localizer task or the main experimental task and computes contrasts 

Add the corresponding folder to the Matlab path. In the runPreprocessing script, add the SPM path and indicate where the BIDS data directory is located. 

## Please Note

The code has not yet been properly tested and verified. Run your own checks and report issues to help improve this pipeline. 

## Built With

* [Matlab](https://de.mathworks.com/products/matlab.html)
* [SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/)

## Acknowledgements

* The code is based on preprocessing code from [Dirk Ostwald's lab](https://www.ipsy.ovgu.de/Institut/Abteilungen+des+Institutes/Methodenlehre+I+_+Experimentelle+und+Neurowissenschaftliche+Psychologie/Team.html)

* [bioRxiv preprint](https://www.biorxiv.org/content/10.1101/253047v1)
* [OSF project](https://osf.io/hkevu/)

## Authors

* **Rasmus Bruckner** - [GitHub](https://github.com/rasmusbruckner) - [FU Berlin](https://www.ewi-psy.fu-berlin.de/en/einrichtungen/arbeitsbereiche/neural_dyn_of_vis_cog/learning-lab/team/bruckner/index.html)
* **Johannes Singer** - [GitHub](https://github.com/Singerjohannes) - [FU Berlin](https://www.ewi-psy.fu-berlin.de/en/einrichtungen/arbeitsbereiche/neural_dyn_of_vis_cog/team_v2/pre_docs/johannes/index.html)


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
