# openpics
Default backend site for the [OpenPics](https://github.com/pj4533/OpenPics) iOS app


## Details

Base URL: http://openpics.herokuapp.com

## Endpoints

##### `GET /images`

Get recently favorited images

Response:
```json

{
  "data": [
    {
      "date": "2014-03-14 18:11:01",
      "id": "1",
      "imageUrl": "http://www.loc.gov/pictures/lcweb2/service/pnp/fsa/8d11000/8d11200/8d11246r.jpg",
      "title": "Chicago, Illinois. A general view of one of the classifications yards of the Chicago and Northwestern Railroad",
      "providerSpecific": {
        "links": {
          "item": "http://www.loc.gov/pictures/item/owi2001010127/PP/",
          "resource": "http://www.loc.gov/pictures/item/owi2001010127/PP/resource/"
        }
      },
      "providerType": "com.saygoodnight.loc",
      "width": "640",
      "height": "475"
    }
    ],
  "paging": {
    "page": "0",
    "limit": 50,
    "total_pages": "35",
    "total_count": "1751"
  }
}
```
