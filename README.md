# Swift-Outline-Collection-ImageView
Collection View Transition to Image View ( Cocoa / macOS )

Combining OutlineView, CollectionView and single ImageView for convenient display of Images in a Directory


On double-click on an item in a Collection View perform a transition into an Image View to show a single image
and vice versa

The development environment now is Xcode 8 under OS X 10.12 aka macOS Sierra.


The storyboard method ( main.storyboard ) is used for coupling AppDelegate, WindowsController and four ViewControllers together. The transition between two view controllers is carried out by a custom storyboard segue. For this procedure I found an excellent article
by John Marstal

- see <http://theiconmaster.com/2015/03/transitioning-between-view-controllers-in-the-same-window-with-swift-mac/>

You will find some useful methods to exchange data between all these objects. I wrote this program to become familiar with the Swift language and to get a feeling how to display images on the screen. It contains a lot of useful stuff regarding handling of windows, menus, images, segues, resizing images for thumbnails, sending notifications and so on. Especially with this project I learned much about using an outline view.

The program is written in Swift 3 and respects the latest changes.


Usage:
The program is starting at the Pictures folder of the current user's account. Afterwards the images of this folder are displayed in a collection view.


When you decide to look more intensely into an image, double click on the single item representing it. Then a transition from the collection view to a single image view is executed, in which the image is shown. The image is scaled so that it fits best into the main Screen.

Both views are supporting now the "Full Screen Mode" of macOS.

The image files can be of different kind, including besides the normal types also EPS, multipage TIFFs and PDF documents.

The sequence of the shown images is controlled by the cursor keys ( look into the menu "Navigate", too ):

- back space : return to collection view

- left : previous image

- right : next image

in case of multi-page TIFFs or PDFs use

- up : previous page of document

- down : next page of document


My thanks go to the Stack Overflow sites. Without the folks there and whose answers this program would not exist.

Disclaimer: Use the program for what purpose you like, but hold in mind, that I will not be responsible for any harm it will cause to your hard- or software. It was your decision to use this piece of software.
