# Statistical Analysis
The scripts in the Statistical Analysis folder contain the algorithms used to verify the measurement methods developed. They also describe the optimal weight selection and uncertainty calculations. 

In order to run this script,  download the rtools library:

	https://cran.r-project.org/bin/windows/Rtools/

Additonal packages may need to be installed using the following command:
	
	packages <- c(
		"ggpubr",
		"dplyr",
		"ggplot2",
		"broom"
		)
	install.packages(packages)

To compile the document using the R Markdown, the tinytex package may be needed. This is acomplished with the following commands:

	install.packages('tinytex')
	tinytex::install_tinytex()

Once this is all taken care of, open cross_tech_validation.rmd in an instance of Rstudio. Locate the *PATH_TO_DATA* variable and set it to the path with published data. Then either knit the document as a pdf or use *crtl+shift+k* and the document will compile.
