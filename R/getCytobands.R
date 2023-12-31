#' getCytobands
#' 
#' @description 
#' 
#' Get the cytobands of the specified genome.
#' 
#' @details 
#'  
#' It returns \code{GRanges} object with the cytobands of the specified genome. 
#' The cytobands for some organisms and genome versions have been pre-downloaded from UCSC
#' and included in the \code{karyoploteR} package. For any other genome, \code{getCytobands}
#' will use \code{rtracklayer} to try to fetch the \code{cytoBandIdeo} table from UCSC. If for
#' some reason it is not possible to retrieve the cytobands, it will return an empty \code{GRanges}
#' object. Setting the parameter \code{use.cache} to \code{FALSE}, the data included in the 
#' package will be ignored and the cytobands will be downloaded from UCSC.
#' 
#' The genomes (and versions) with pre-downloaded cytobands are: hg18, hg19, hg38, mm9, mm10, mm39, 
#'      rn5, rn6, rn7, susScr11, 
#'      bosTau9, bosTau8, equCab3, equCab2, panTro6, panTro5, rheMac10,
#'      danRer10, danRer11, xenTro10, dm3, dm6, 
#'      ce6, ce10, ce11, sacCer2, sacCer3
#'    
#' 
#' 
#' @usage getCytobands(genome="hg19", use.cache=TRUE)
#' 
#' @param genome   (character or other) specifies a genome using the UCSC genome name. Defaults to "hg19". If it's not a \code{character}, genome is ignored and and empty \code{GRanges} is returned.
#' @param use.cache   (boolean) wether to use or not the cytoband information included in the packge. \code{use.cache=FALSE} will force a download from the UCSC.
#' 
#' @return
#' It returns a \code{\link{GenomicRanges}} object with the cytobands of the specified genome. If no cytobands are available for any reason, an empty \code{GRanges} is returned.
#' 
#' 
#' @note 
#' 
#' This function is memoised (cached) using the \code{\link{memoise}} package. To empty the 
#' cache, use \code{\link{forget}(getCytobands)}
#'  
#' @seealso \code{\link{plotKaryotype}}
#' 
#' @examples
#'  
#' #get the cytobands for hg19 (using the data included in the package)
#' cyto <- getCytobands("hg19")
#' 
# #Example deactivated due to a warning in biovizbase code
# #do not use the included data and force the download from UCSC
# cyto <- getCytobands("hg19", use.cache=FALSE)
#' 
#' #get the cytobands for Drosophila Melanogaster
#' cyto <- getCytobands("dm6")
#' 
#'  
#' @export getCytobands
#' 
#' @importFrom biovizBase getIdeogram
#' 


getCytobands <- NULL #Neede so roxygen writes the documentation file


#This is the internal function used. The exported and memoised version is created on-load 
#time as a memoised version of this.

.getCytobands <- function(genome="hg19", use.cache=TRUE) {
  #if it's a custom genome, do not attempt to get the cytobands
  if(!is.character(genome) | length(genome)>1) { 
    return(GRanges())
  }
  
  #If the cytobands are in the included cache, use them
  if(use.cache) {
    if(genome %in% names(data.cache[["cytobands"]])) {
      return(data.cache[["cytobands"]][[genome]])
    }
  }
    
  cytobands <- tryCatch(expr={
    #TEMP FIX: 2023-08-28 I deactivate the call to biovizBase due to an error: 
    #   Error in .normarg_seqlengths(value, seqnames(x)) : 
    #   the names on the supplied 'seqlengths' vector must be identical to the seqnames
    #and activate the old code directly calling rtracklayer to access UCSC.
    #TODO: Fall back to bioviz base once this is fixed.
    
    #biovizBase::getIdeogram(genome, cytobands=TRUE, )
    #Old version. Changed to a dependency on boivizBase as requested by package reviewer.    
    ucsc.session <- rtracklayer::browserSession()
    rtracklayer::genome(ucsc.session) <- genome
    cytobands <- rtracklayer::getTable(rtracklayer::ucscTableQuery(ucsc.session,"cytoBandIdeo"))
    cytobands$name <- as.character(cytobands$name)
    cytobands$gieStain <- as.character(cytobands$gieStain)
    toGRanges(cytobands)
    },
    error = function(e) {
      message("Message: Failed to retrieve cytobands for ", genome, " from UCSC. Returning no cytobands.", e)
      return(GRanges())
    }
  )
  cytobands$name <- as.character(cytobands$name)
  cytobands$gieStain <- as.character(cytobands$gieStain)
  
  return(cytobands)
  
}



# # #Code used to save the predownloaded Cytobands for some common genomes
# genomes <- c("hg18", "hg19", "hg38", "mm9", "mm10", "mm39", "rn5", "rn6", "rn7", "susScr11", 
#              "bosTau9", "bosTau8", "equCab3", "equCab2", "panTro6", "panTro5", "rheMac10",
#              "danRer10", "danRer11", "xenTro10", "dm3", "dm6", 
#              "ce6", "ce10", "ce11", "sacCer2", "sacCer3")
# 
# cytobands.cache <- list()
# genomes.cache <- list()
# 
# for(g in genomes) {
#   message("Downloading data for ", g)
#   cytobands.cache[[g]] <- getCytobands(g, use.cache=FALSE)
#   genomes.cache[[g]] <- GRangesForUCSCGenome(genome=g)
#   Sys.sleep(200)  #To ensure no blocking from UCSC due to too many requests
# }
# 
# data.cache <- list(genomes=genomes.cache, cytobands=cytobands.cache)
# 
# library(devtools)
# use_data(data.cache, internal = TRUE, overwrite=TRUE)
#  
# load("R/sysdata.rda")
# data.cache

#OLD CODE
# cytobands.cache <- list()
# cytobands.cache[["hg19"]] <- getCytobands("hg19", use.cache=FALSE)
# cytobands.cache[["hg38"]] <- getCytobands("hg38", use.cache=FALSE)
# cytobands.cache[["mm9"]] <- getCytobands("mm9", use.cache=FALSE)
# cytobands.cache[["mm10"]] <- getCytobands("mm10", use.cache=FALSE)
# cytobands.cache[["rn5"]] <- getCytobands("rn5", use.cache=FALSE)
# cytobands.cache[["rn6"]] <- getCytobands("rn6", use.cache=FALSE)
# cytobands.cache[["danRer10"]] <- getCytobands("danRer10", use.cache=FALSE)
# cytobands.cache[["dm6"]] <- getCytobands("dm6", use.cache=FALSE)
# cytobands.cache[["ce6"]] <- GRanges()
# cytobands.cache[["sacCer3"]] <- GRanges()
# 
# genomes.cache <- list()
# genomes.cache[["hg19"]] <- GRangesForUCSCGenome(genome="hg19")
# genomes.cache[["hg38"]] <- GRangesForUCSCGenome(genome="hg38")
# genomes.cache[["mm9"]] <- GRangesForUCSCGenome(genome="mm9")
# genomes.cache[["mm10"]] <- GRangesForUCSCGenome(genome="mm10")
# genomes.cache[["rn5"]] <- GRangesForUCSCGenome(genome="rn5")
# genomes.cache[["rn6"]] <- GRangesForUCSCGenome(genome="rn6")
# genomes.cache[["danRer10"]] <- GRangesForUCSCGenome(genome="danRer10")
# genomes.cache[["dm6"]] <- GRangesForUCSCGenome(genome="dm6")
# genomes.cache[["ce6"]] <- GRangesForUCSCGenome(genome="ce6")
# genomes.cache[["sacCer3"]] <- GRangesForUCSCGenome(genome="sacCer3")
# 
# data.cache <- list(genomes=genomes.cache, cytobands=cytobands.cache)
# library(devtools)
# use_data(data.cache, internal = TRUE, overwrite=TRUE)
# 
# load("R/sysdata.rda")
# data.cache
