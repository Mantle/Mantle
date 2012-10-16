//
//  CGGeometry+MTLConvenienceAdditions.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 18.01.12.
//  Copyright 2012 GitHub. All rights reserved.
//

/*

Portions copyright (c) 2012, Bitswift, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Neither the name of the Bitswift, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#import <CoreGraphics/CoreGraphics.h>

// Returns the exact center point of the given rectangle.
CGPoint CGRectCenterPoint (CGRect rect);

// Chops the given amount off of a rectangle's edge.
//
// Returns the remainder of the rectangle, or `CGRectZero` if `amount` is
// greater than or equal to size of the rectangle along the axis being chopped.
CGRect CGRectRemainder (CGRect rect, CGFloat amount, CGRectEdge edge);

// Returns a slice consisting of the given amount starting from a rectangle's
// edge, or the entire rectangle if `amount` is greater than or equal to the
// size of the rectangle along the axis being sliced.
CGRect CGRectSlice (CGRect rect, CGFloat amount, CGRectEdge edge);

// Adds the given amount to a rectangle's edge.
//
// rect   - The rectangle to grow.
// amount - The amount of points to add.
// edge   - The edge from which to grow. Growing is always outward (i.e., using
//          `CGRectMaxXEdge` will increase the width of the rectangle and leave
//          the origin unmodified).
CGRect CGRectGrow (CGRect rect, CGFloat amount, CGRectEdge edge);

// Divides a source rectangle into two component rectangles, skipping the given
// amount of padding in between them.
//
// This functions like CGRectDivide(), but omits the specified amount of padding
// between the two rectangles. This results in a remainder that is `padding`
// points smaller from `edge` than it would be with CGRectDivide().
//
// rect        - The rectangle to divide.
// slice       - Upon return, the portion of `rect` starting from `edge` and
//				 continuing for `sliceAmount` points. This argument may be NULL
//				 to not return the slice.
// remainder   - Upon return, the portion of `rect` beginning `padding` points
//               after the end of the `slice`. If `rect` is not large enough to
//               leave a remainder, this will be `CGRectZero`. This argument may
//               be NULL to not return the remainder.
// sliceAmount - The number of points to include in `slice`, starting from the
//               given edge.
// padding     - The number of points of padding to omit between `slice` and
//               `remainder`.
// edge        - The edge from which division begins, proceeding toward the
//               opposite edge.
void CGRectDivideWithPadding (CGRect rect, CGRect *slice, CGRect *remainder, CGFloat sliceAmount, CGFloat padding, CGRectEdge edge);

// Round down fractional X origins (moving leftward on screen), round
// up fractional Y origins (moving upward on screen), and round down fractional
// sizes, such that the size of the rectangle will never increase just
// from use of this method.
//
// This function differs from CGRectIntegral() in that the resultant rectangle
// may not completely encompass `rect`. CGRectIntegral() will ensure that its
// resultant rectangle encompasses the original, but may increase the size of
// the result to accomplish this.
CGRect CGRectFloor(CGRect rect);

// Creates a rectangle for a coordinate system originating in the bottom-left.
//
// containingRect - The rectangle that will "contain" the created rectangle,
//                  used as a reference to vertically flip the coordinate system.
// x              - The X origin of the rectangle, starting from the left.
// y              - The Y origin of the rectangle, starting from the top.
// width          - The width of the rectangle.
// height         - The height of the rectangle.
CGRect CGRectMakeInverted (CGRect containingRect, CGFloat x, CGFloat y, CGFloat width, CGFloat height);

// Vertically inverts the coordinates of `rect` within `containingRect`.
//
// This can effectively be used to change the coordinate system of a rectangle.
// For example, if `rect` is defined for a coordinate system starting at the
// top-left, the result will be a rectangle relative to the bottom-left.
//
// containingRect - The rectangle that will "contain" the created rectangle,
//                  used as a reference to vertically flip the coordinate system.
// rect           - The rectangle to vertically flip within `containingRect`.
CGRect CGRectInvert (CGRect containingRect, CGRect rect);

// Returns a rectangle with an origin of `CGPointZero` and the given size.
CGRect CGRectWithSize (CGSize size);

// Returns whether every side of `rect` is within `epsilon` distance of `rect2`.
BOOL CGRectEqualToRectWithAccuracy (CGRect rect, CGRect rect2, CGFloat epsilon);

// Returns whether `size` is within `epsilon` points of `size2`.
BOOL CGSizeEqualToSizeWithAccuracy (CGSize size, CGSize size2, CGFloat epsilon);

// Scales the components of `size` by `scale`.
CGSize CGSizeScale(CGSize size, CGFloat scale);

// Rounds a point to integral numbers. The point will always be moved up and
// left, in view coordinates, so `x` will be rounded down and `y` will be
// rounded up.
CGPoint CGPointFloor(CGPoint point);

// Returns whether `point` is within `epsilon` distance of `point2`.
BOOL CGPointEqualToPointWithAccuracy(CGPoint point, CGPoint point2, CGFloat epsilon);

// Returns the dot product of two points.
CGFloat CGPointDotProduct(CGPoint point, CGPoint point2);

// Returns `point` scaled by `scale`.
CGPoint CGPointScale(CGPoint point, CGFloat scale);

// Returns the length of `point`.
CGFloat CGPointLength(CGPoint point);

// Returns the unit vector of `point`.
CGPoint CGPointNormalize(CGPoint point);

// Returns a projected point in the specified direction.
CGPoint CGPointProject(CGPoint point, CGPoint direction);

// Returns the angle of a vector.
CGFloat CGPointAngleInDegrees(CGPoint point);

// Projects a point along a specified angle.
CGPoint CGPointProjectAlongAngle(CGPoint point, CGFloat angleInDegrees);

// Add `p1` and `p2`.
CGPoint CGPointAdd(CGPoint p1, CGPoint p2);

// Subtracts `p2` from `p1`.
CGPoint CGPointSubtract(CGPoint p1, CGPoint p2);
