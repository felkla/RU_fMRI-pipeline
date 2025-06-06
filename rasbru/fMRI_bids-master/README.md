# Gabor-Bandit BIDS Conversion

This repository contains the code to convert Gabor-Bandit fMRI data into [BIDS](http://bids.neuroimaging.io) format.

## Getting Started

The code requires access to the raw data, which are not publicly available. We have two main files:

* gb_bids: This script converts the raw data to BIDS format
* gb_bidsobj: Gabor-bandit BIDS conversion class definition file

Add the gb_bids folder to the Matlab path. In the gb_bids script, add the SPM, JSONLAB and dicm2nii paths and indicate where the data as well as the BIDS directory are located. 

## Built With

* [Matlab](https://de.mathworks.com/products/matlab.html)
* [SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/)
* [dicm2nii](https://de.mathworks.com/matlabcentral/fileexchange/42997-xiangruili-dicm2nii)
* [JSONLAB](https://de.mathworks.com/matlabcentral/fileexchange/33381-jsonlab-a-toolbox-to-encode-decode-json-files)

## Acknowledgements

* The code is based on BIDS conversion code written by [Lilla Horvath](https://www.ewi-psy.fu-berlin.de/einrichtungen/arbeitsbereiche/computational_cogni_neurosc/people/horvath/index.html)

## Authors

* **Rasmus Bruckner** - [GitHub](https://github.com/rasmusbruckner) - [IMPRS LIFE](https://www.imprs-life.mpg.de/de/people/rasmus-bruckner)
* **Felix Molter** - [IMPRS LIFE](https://www.imprs-life.mpg.de/de/people/felix-molter)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
