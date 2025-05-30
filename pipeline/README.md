# README

## Alignment rates

Comparing the alignment rates between indoor (T89) and outdoor (tremula) samples.

We first get the mapping rate by sample from the salmon results.

```bash
cd data/salmon
find . -name meta_info.json | xargs -I {} bash -c 'echo $(echo $0 | cut -d_ -f1,2 | cut -d/ -f2) $(grep "percent_mapped" $0 | cut -d: -f2 | sed s:,::)' {}
```

Then we combine it with the sample information from the doc/Sample-annotation-transcriptomic-project.csv file.

Finally, we plot it in R.

```R
library(tidyverse)

dat <- read_tsv("~/Downloads/Sample-annotation-transcriptomic-project.txt",
                show_col_types = FALSE) %>% 
  mutate(Genotype=ifelse(Location=="Indoor","T89","Tremula"))

ggplot(dat,aes(x=Genotype,y=MappingRate,col=Genotype)) +
  geom_violin() + geom_boxplot(outliers=FALSE,notch = TRUE,width=0.5)

t.test(dat$MappingRate[dat$Location=="Indoor"],
       dat$MappingRate[dat$Location=="Outdoor"])
```
