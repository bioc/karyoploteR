#' kpPlotBigWig
#' 
#' @description 
#' 
#' Plots the wiggle values in a BigWig file. This function does not work on windows.
#' 
#' @details 
#'  
#' \code{kpPlotBigWig} plots the data contained in a binary file format called 
#' BigWig. BigWig are used to efficiently store numeric values computed for 
#' windows covering the whole genome, ususally the coverage from an NGS 
#' experiment such as ChIP-seq. Only data required for the plotted region
#' is loaded, and when more than one chromosome is visible, it will load the
#' data for one crhomosome at a time.
#' The function accepts either a \code{\link{BigWigFile}} oject or a 
#' \code{character} with the path to a valid big wig file. The character can 
#' also be a URL to a remote server. In this case data will be loaded 
#' transparently using the \code{import} function from 
#' \code{rtracklayer}.  
#' The data is plotted using \code{\link{kpArea}} and therefore it is possible
#' to plot as a single line, a line with shaded area below or as a shaded area 
#' only adjusting the \code{col} and \code{border} parameters. 
#' 
#' 
#' @usage kpPlotBigWig(karyoplot, data, ymin=NULL, ymax="global", data.panel=1, r0=NULL, r1=NULL, col=NULL, border=NULL, clipping=TRUE, ...) 
#' 
#' @param karyoplot    (a \code{KaryoPlot} object) This is the first argument to all data plotting functions of \code{karyoploteR}. A KaryoPlot object referring to the currently active plot.
#' @param data    (a \code{BigWigFile} or character) The path to a bigwig file (either local or a URL to a remote file) or a \code{BigWigFile} object.
#' @param data.panel    (numeric) The identifier of the data panel where the data is to be plotted. The available data panels depend on the plot type selected in the call to \code{\link{plotKaryotype}}. (defaults to 1)
#' @param r0    (numeric) r0 and r1 define the vertical range of the data panel to be used to draw this plot. They can be used to split the data panel in different vertical ranges (similar to tracks in a genome browser) to plot differents data. If NULL, they are set to the min and max of the data panel, it is, to use all the available space. (defaults to NULL)
#' @param r1    (numeric) r0 and r1 define the vertical range of the data panel to be used to draw this plot. They can be used to split the data panel in different vertical ranges (similar to tracks in a genome browser) to plot differents data. If NULL, they are set to the min and max of the data panel, it is, to use all the available space. (defaults to NULL)
#' @param ymin    (numeric) The minimum value to be plotted on the data panel. If NULL, the minimum between 0 and the minimum value in the WHOLE GENOME will be used. (deafults to NULL)
#' @param ymax    (numeric or c("global", "per.chr", "visible.region")) The maximum value to be plotted on the data.panel. It can be either a numeric value or one of c("global", "per.chr", "per.region"). "Global" will set ymax to the maximum value in the whole data file. "per.chr" will set ymax to the maximum value in each chromosome. "visible.region" will set ymax to the maximum value in the visible region. (defaults to "global")
#' @param col  (color) The fill color of the area. A single color. If NULL the color will be assigned automatically, either a lighter version of the color used for the outer line or gray if the line color is not defined. If NA no area will be drawn. (defaults to NULL)
#' @param border  (color) The color of the line enclosing the area. A single color. If NULL the color will be assigned automatically, either a darker version of the color used for the area or black if col=NA. If NA no border will be drawn. (Defaults to NULL)
#' @param clipping  (boolean) Only used if zooming is active. If TRUE, the data representation will be not drawn out of the drawing area (i.e. in margins, etc) even if the data overflows the drawing area. If FALSE, the data representation may overflow into the margins of the plot. (defaults to TRUE)
#' @param ...    The ellipsis operator can be used to specify any additional graphical parameters. Any additional parameter will be passed to the internal calls to the R base plotting functions.
#'   
#' @return
#' 
#' Returns the original karyoplot object with the data computed (ymax and ymin values used) stored at \code{karyoplot$latest.plot}
#' 
#' @note Since this functions uses \code{rtracklayer} BigWig infrastructure and it does not work on windows, this function won't work on windows either.
#' 
#' @seealso \code{\link{plotKaryotype}}, \code{\link{kpArea}}, \code{\link{kpPlotBAMDensity}}
#' 
#' @examples
#' 
#' if (.Platform$OS.type != "windows") {
#'   bigwig.file <- system.file("extdata", "BRCA.genes.hg19.bw", package = "karyoploteR")
#'   brca.genes.file <- system.file("extdata", "BRCA.genes.hg19.txt", package = "karyoploteR")
#'   brca.genes <- toGRanges(brca.genes.file)
#'   seqlevelsStyle(brca.genes) <- "UCSC"
#' 
#'   kp <- plotKaryotype(zoom = brca.genes[1])
#'   kp <- kpPlotBigWig(kp, data=bigwig.file, r0=0, r1=0.2)
#'   kp <- kpPlotBigWig(kp, data=bigwig.file, r0=0.25, r1=0.45, border="red", lwd=2)
#'   kp <- kpPlotBigWig(kp, data=bigwig.file, r0=0.5, r1=0.7, ymin=0, ymax=1000, border="gold", col=NA)
#'   kpAxis(kp, r0=0.5, r1=0.7, ymin=0, ymax=1000)
#'   kp <- kpPlotBigWig(kp, data=bigwig.file, r0=0.75, r1=0.95, ymin=0, ymax="visible.region", border="orchid", col=NA)
#'   kpAxis(kp, r0=0.75, r1=0.95, ymin=0, ymax=kp$latest.plot$computed.values$ymax)
#' }
#' 
#' 
#' @export kpPlotBigWig
#' @importFrom rtracklayer BigWigFile seqinfo summary
#' @importFrom S4Vectors intersect
#' 


kpPlotBigWig <- function(karyoplot, data, ymin=NULL, ymax="global", data.panel=1, 
                         r0=NULL, r1=NULL, 
                         col=NULL, border=NULL, clipping=TRUE, ...) {
  
  #karyoplot
  if(missing(karyoplot)) stop("The parameter 'karyoplot' is required")
  if(!methods::is(karyoplot, "KaryoPlot")) stop("'karyoplot' must be a valid 'KaryoPlot' object")
  
  #data
  if(missing(data)) stop("The parameter 'data' is required")
  if(!methods::is(data, "BigWigFile") & !methods::is(data, "character")) stop("'data' must be a character or a BigWigFile object")
  
  #Prepare the access to the data
  if(methods::is(data, "character")) {
    data <- rtracklayer::BigWigFile(data)
  }
  
  #Check ymax
  if(is.null(ymax)) ymax <- "global"
  if(!all(is.numeric(ymax))) {
    ymax <- match.arg(ymax, choices = c("global", "per.chr", "visible.region"))
  }
  
  
  #Check seqinfo(data) to validate at least some intersection between the genome
  #and data chromosome names
  data.chrs <- seqnames(seqinfo(data))
  if(!any(data.chrs %in% karyoplot$chromosomes)) {
    #NOTE: We can deactivate this warning and make it fail silently. Not sure 
    #      what the best option is yet
    warning("None of the chromosome names in the data file (", 
            paste0(data.chrs, collapse = ","), 
            ") matches a chromosome name in the plotted genome (", 
            paste0(karyoplot$chromosomes, collapse=","), "). Nothing will be plotted")
  }
  
  #if ymax is NULL, set it to the maximum of the file on the whole genome using
  # the summary info from BigWigFile or 0 if all values are negative
  if(all(is.numeric(ymax))) {
    ymax <- setNames(rep(ymax, length.out=length(karyoplot$plot.region)),
                     as.character(seqnames(karyoplot$plot.region)))
  } else {
    if(length(ymax)==1 && ymax=="global") {
      max.vals <- unlist(summary(data, type="max"))
      ymax <- setNames(rep(max(0, max(mcols(max.vals)[,1])), length(max.vals)), as.character(seqnames(max.vals)))
    }
    if(length(ymax)==1 && ymax=="per.chr") {
      max.vals <- unlist(summary(data, type="max"))
      ymax <- setNames(mcols(max.vals)[,1], as.character(seqnames(max.vals)))
    }
  }    

  #if ymin is NULL, set it to the minimum of the file on the whole genome or 0 
  #if all values are above 0
  if(is.null(ymin)) {
    ymin <- min(0, min(mcols(unlist(summary(data, type="min")))[,1]))
  }
  
  
  #Load and plot the data serially for each chromosome. This will reduce the 
  # memory load when plotting on the whole genome
  
  #Filter out the plot regions (i.e. chromosomes) not known to data. This reduces work and avoids warnings about unknown seqlevels
  plot.region <- GenomeInfoDb::keepSeqlevels(karyoplot$plot.region, value = S4Vectors::intersect(seqlevels(data), seqlevels(karyoplot$plot.region)), pruning.mode = "coarse")
  
  for(i in seq_along(plot.region)) {
    #Note: remove unneeded seqlevels when calling import to avoid a warning about unknown seqlevels
    wig.data <- rtracklayer::import(data, format = "bigWig", selection=plot.region[i])
    if(all(is.numeric(ymax))) {
      region.ymax <- ymax[as.character(seqnames(plot.region[i]))]
    } else {
      if(length(ymax)==1 && ymax == "visible.region") {
        region.ymax <- max(0, max(mcols(wig.data)[,1]))
      } else {
        stop("Unexpected ymax value")
      }
    }
    kpArea(karyoplot, data = wig.data, y=wig.data$score, 
           ymin=ymin, ymax=region.ymax,
           data.panel=data.panel, r0=r0, r1=r1,
           col=col, border=border, clipping=TRUE, ...)
  }
  
  #TODO: Should return all ymax values instead of using only the last one
  karyoplot$latest.plot <- list(funct="kpPlotBigWig", computed.values=list(ymax=region.ymax, ymin=ymin))
  
  
  invisible(karyoplot)
}
