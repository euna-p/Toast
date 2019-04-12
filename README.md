# TOAST

[![WTFPL](http://www.wtfpl.net/wp-content/uploads/2012/12/wtfpl-badge-1.png)](http://www.wtfpl.net)

It's a usable to very simply toast in swift.

### **features**
  - Overlap to UI screen keyboard.
  - Easily show string or attributed string.
  - Easily set displaying duration and position.

### **CocoaPods**
> [https://cocoapods.org/pods/FLToast](https://cocoapods.org/pods/FLToast)
>
> ``` pod 'FLToast', '~> 1.0.0' ```
>
> Add in '**Podfile**'. and run **pod install**.
>
> ``` import Toast ```
>
> Add swift code in your project.

### **How To Use**
> ``` Toast(text: "It's a SIMPLE Toast message.").show() ```
>
> *This is the most basic usage.*

> ``` let attributedString = NSMutableAttributedString(string: "It's an Attributed Toast message.\n", attributes: [.font: UIFont.systemFont(ofSize: 14.0), .foregroundColor: UIColor.red]) ```
>
> ``` Toast(text: attributedString).show() ```
>
> *It's show an attributed string.*

> ``` Toast.makeText("It's a Top Toast message.").setGravity(.top).show() ```
>
> or
>
> ``` Toast.makeText("It's a Middle Toast message.").setGravity(.middle).show() ```
>
> or
>
>``` Toast.makeText("It's a Top Bottom message.").setGravity(.bottom).show() ```
>
> *It can a specify the display position of message.*

> ``` Toast.makeText("It's a Long (5s) Toast message.").setDuration(.long).show() ```
>
> or
>
>``` Toast.makeText("It's a Custom Duration (10s) Toast message.").setDuration(10.0).show() ```
>
> *It can specify the display duration of the message.*
