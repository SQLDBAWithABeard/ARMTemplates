## FInding images

Login-AzureRmAccount

$loc = Get-AzureRmLocation | OGV -passthru | select Location #first set a location
#View the templates available
$publisher=Get-AzureRmVMImagePublisher -Location $loc.Location |OGV -passthru | select publishername #check all the publishers available
$offer=Get-AzureRmVMImageOffer -Location $loc.Location -PublisherName $publisher.PublisherName|OGV -passthru |select offer #look for offers for a publisher
$sku=Get-AzureRmVMImageSku -Location $loc.Location -PublisherName $publisher.PublisherName -Offer $offer.Offer | OGV -passthru |select skus #view SKUs for an offer
Get-AzureRmVMImage -Location $loc.Location -PublisherName $publisher.PublisherName -Offer $offer.Offer -Skus $sku.Skus #pick one!