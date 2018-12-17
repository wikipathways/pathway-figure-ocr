<?php

$htmldir = '20181216/rawhtml/'; 
$outdir = '20181216/figures/';
$ncbi = "http://www.ncbi.nlm.nih.gov";

foreach(glob($htmldir.'*.html') as $fn){
	echo $fn, "\n";
	$stuff = file_get_contents($fn);
	preg_match_all('/src-large\=\"(.*?)\"/', $stuff, $imgurl);
	foreach($imgurl[1] as $name){
		echo $name, "\n";
                preg_match('/instance\/(\d+)\/bin\/(.*)$/', $name, $matches);
		$pmcid = "PMC" . $matches[1];
		$originalFilename = $matches[2];
                $imageFilename = $outdir . $pmcid . "__" . $originalFilename;
                $url = $ncbi . $name;
                $imageContent = file_get_contents($url);
                file_put_contents($imageFilename, $imageContent);
	}
}

?>
