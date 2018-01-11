<?php
include 'simple_html_dom.php';

$htmldir = 'pmc/signaling_pathway/1.1_rawhtml/'; 
$outdir = 'pmc/signaling_pathway/1.1.1_figures/';
$ncbi = "http://www.ncbi.nlm.nih.gov";

foreach(glob($htmldir.'*.html') as $fn){
	$dom = new DOMDocument;
	$html = file_get_html($fn);
	libxml_use_internal_errors(true);
	$dom->loadHTML($html);
	libxml_use_internal_errors(false);

	$results = $html->find('div.rslt'); //each result is encapsulated by div.rlst
	foreach($results as $rslt){
		
		$caption = $rslt->find('div.rprt_cont p.details');

		//Process image tag from result and write
		$image = $rslt->find('img');
                $name = $image[0]->getAttribute('src-large');
                preg_match('/instance\/(\d+)\/bin\/(.*)$/', $name, $matches);
		$pmcid = "PMC" . $matches[1];
		$originalFilename = $matches[2];
                $imageFilename = $outdir . $pmcid . "__" . $originalFilename;
                $url = $ncbi . $name;
                $imageContent = file_get_contents($url);
                file_put_contents($imageFilename, $imageContent);

		//Process caption-related tags from result and write
		$title = $rslt->find('div.rprt_cont p.title');
                $titleTxt = $title[0]->innertext;
		$captionTxt = '<div class="p4l_caption"><div class="p4l_captionTitle">';
		$captionTxt .= str_replace ('href="/pmc','target="_blank" href="' . $ncbi . '/pmc', $titleTxt);
		$captionTxt .= '</div><br /><div class="p4l_captionBody">';
                $details = $rslt->find('div.rprt_cont p.details');
                $detailsTxt = strip_tags($caption[0]->innertext, '<b>');
                $captionTxt .= $detailsTxt . "</div></div>";
		$captionFilename = $outdir . $pmcid . "__" . $originalFilename. '.html';
		file_put_contents($captionFilename, $captionTxt);		
 	}
	
}

?>
