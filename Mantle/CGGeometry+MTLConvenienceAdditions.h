//
//  CGGeometry+MTLConvenienceAdditions.h
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

/**
 * Returns the exact center point of the given rectangle.
 *
 * @param rect The rectangle to return the center of.
 */
CGPoint CGRectCenterPoint (CGRect rect);

/**
 * Chops the given amount off of a rectangle's edge, returning the remainder.
 *
 * If `amount` is greater than or equal to the size of the rectangle along the
 * axis being chopped, `CGRectZero` is returned.
 *
 * @param rect The rectangle to divide.
 * @param amount The amount of points to remove.
 * @param edge The edge from which to chop.
 */
CGRect CGRectRemainder (CGRect rect, CGFloat amount, CGRectEdge edge);

/**
 * Returns a slice consisting of the given amount starting from a rectangle's
 * edge.
 *
 * If `amount` is greater than or equal to the size of the rectangle along the
 * axis being chopped, the entire rectangle is returned.
 *
 * @param rect The rectangle to divide.
 * @param amount The amount of points to return in the slice.
 * @param edge The edge from which to slice.
 */
CGRect CGRectSlice (CGRect rect, CGFloat amount, CGRectEdge edge);

/**
 * Adds the given amount to a rectangle's edge.
 *
 * @param rect The rectangle to grow.
 * @param amount The amount of points to add.
 * @param edge The edge from which to grow. Growing is always outward (i.e.,
 * using `CGRectMaxXEdge` will increase the width of the rectangle and leave the
 * origin unmodified).
 */
CGRect CGRectGrow (CGRect rect, CGFloat amount, CGRectEdge edge);

/**
 * Divides a source rectangle into two component rectangles, determined by
 * "cutting out" a region that intersects with another rectangle.
 *
 * This function will do the following:
 *
 *  1. Determine the intersection of `rect` and `intersectingRect`.
 *  2. If `rect` does not intersect `intersectingRect`, set `slice` to `rect`,
 *  set `remainder` to `CGRectNull`, and return immediately.
 *  3. _Starting from_ the given edge, cut `rect` until the start of the
 *  intersection is reached. If the intersection starts outside of `rect`, set
 *  `slice` to `CGRectNull`; otherwise, set `slice` to the cut region (which may
 *  be of zero size along the cutting axis).
 *  4. Starting from the given edge, skip the entire length of the intersection.
 *  5. If the intersection ends outside of `rect`, set `remainder` to
 *  `CGRectNull`; otherwise, set `remainder` to whatever region of `rect`
 *  remains (which may be of zero size along the cutting axis).
 *
 * @param rect The rectangle to divide.
 * @param slice Upon return, the portion of `rect` starting from `edge` and
 * continuing until the intersection of `rect` and `intersectingRect`. This
 * argument may be `NULL` to not return the slice.
 * @param remainder Upon return, the portion of `rect` starting _after_ the
 * intersection of `rect` and `intersectingRect`, and continuing until the end
 * of `rect`. This argument may be `NULL` to not return the remainder.
 * @param intersectingRect A rectangle to intersect with `rect` in order to
 * determine where and how much to cut.
 * @param edge The edge from which cutting begins, with cutting proceeding
 * toward the opposite edge.
 */
void CGRectDivideExcludingIntersection (CGRect rect, CGRect *slice, CGRect *remainder, CGRect intersectingRect, CGRectEdge edge);

/**
 * Divides a source rectangle into two component rectangles, skipping the given
 * amount of padding in between them.
 *
 * This functions like `CGRectDivide()`, but omits the specified amount of
 * padding between the two rectangles. This results in a remainder that is
 * `padding` points smaller from `edge` than it would be with `CGRectDivide()`.
 *
 * @param rect The rectangle to divide.
 * @param slice Upon return, the portion of `rect` starting from `edge` and
 * continuing for `sliceAmount` points. This argument may be `NULL` to not
 * return the slice.
 * @param remainder Upon return, the portion of `rect` beginning `padding`
 * points after the end of the `slice`. If `rect` is not large enough to leave
 * a remainder, this will be `CGRectZero`. This argument may be `NULL` to not
 * return the remainder.
 * @param sliceAmount The number of points to include in `slice`, starting from
 * the given edge.
 * @param padding The number of points of padding to omit between `slice` and
 * `remainder`.
 * @param edge The edge from which division begins, proceeding toward the
 * opposite edge.
 */
void CGRectDivideWithPadding (CGRect rect, CGRect *slice, CGRect *remainder, CGFloat sliceAmount, CGFloat padding, CGRectEdge edge);

/**
 * Round down fractional X origins (moving leftward on screen), round
 * up fractional Y origins (moving upward on screen), and round down fractional
 * sizes, such that the size of the rectangle will never increase just
 * from use of this method.
 *
 * This function differs from `CGRectIntegral` in that the resultant rectangle
 * may not completely encompass `rect`. `CGRectIntegral` will ensure that its
 * resultant rectangle encompasses the original, but may increase the size of
 * the result to accomplish this.
 *
 * @param rect The `CGRect` to adjust.
 */
CGRect CGRectFloor(CGRect rect);

/**
 * Creates a rectangle for a coordinate system originating in the bottom-left.
 *
 * @param containingRect The rectangle that will "contain" the created
 * rectangle, used as a reference to vertically flip the coordinate system.
 * @param x The X origin of the rectangle, starting from the top-left.
 * @param y The Y origin of the rectangle, starting from the top-left.
 * @param width The width of the rectangle.
 * @param height The height of the rectangle.
 */
CGRect CGRectMakeInverted (CGRect containingRect, CGFloat x, CGFloat y, CGFloat width, CGFloat height);

/**
 * Vertically inverts the coordinates of `rect` within `containingRect`.
 *
 * This can effectively be used to change the coordinate system of a rectangle.
 * For example, if `rect` is defined for a coordinate system starting at the
 * top-left, the result will be a rectangle relative to the bottom-left.
 *
 * @param containingRect The rectangle that will "contain" the created
 * rectangle, used as a reference to vertically flip the coordinate system.
 * @param rect The rectangle to vertically flip within `containingRect`.
 */
CGRect CGRectInvert (CGRect containingRect, CGRect rect);

/**
 * Creates and returns a rectangle with an origin of `CGPointZero` and the given
 * size.
 *
 * @param size The size of rectangle to create.
 */
CGRect CGRectWithSize (CGSize size);

/**
 * Returns whether every side of `rect` is within `epsilon` distance of `rect2`.
 *
 * @param rect The first rectangle.
 * @param rect2 The second rectangle.
 * @param epsilon The acceptable distance between the sides of `rect` and
 * `rect2`.
 */
BOOL CGRectEqualToRectWithAccuracy (CGRect rect, CGRect rect2, CGFloat epsilon);

/**
 * Returns whether `size` is within `epsilon` points of `size2`.
 *
 * @param size The first size.
 * @param size2 The second size.
 * @param epsilon The acceptable difference between `size` and `size2`.
 */
BOOL CGSizeEqualToSizeWithAccuracy (CGSize size, CGSize size2, CGFloat epsilon);

/**
 * Scales the components of `size` by `scale`.
 *
 * @param size The size to be scaled.
 * @param scale The scale factor.
 */
CGSize CGSizeScale(CGSize size, CGFloat scale);

/**
 * Returns a point with `x` and `y` components rounded to whole numbers. The
 * point will always be moved up and left, in view coordinates, so `x` will be
 * rounded down and `y` will be rounded up.
 *
 * @param point The point to round.
 */
CGPoint CGPointFloor(CGPoint point);

/**
 * Returns whether `point` is within `epsilon` distance of `point2`.
 *
 * @param point The first point.
 * @param point2 The second point.
 * @param epsilon The acceptable distance between `point` and `point2`.
 */
BOOL CGPointEqualToPointWithAccuracy(CGPoint point, CGPoint point2, CGFloat epsilon);

/**
 * Returns the dot product of two points.
 *
 * @param point The first specified point.
 * @param point2 The second specified point.
 */
CGFloat CGPointDotProduct(CGPoint point, CGPoint point2);

/**
 * Returns `point` scaled by `scale`.
 *
 * @param point The specified point.
 * @param scale The specified scaling factor.
 */
CGPoint CGPointScale(CGPoint point, CGFloat scale);

/**
 * Returns the length of `point`.
 *
 * @param point The specified point.
 */
CGFloat CGPointLength(CGPoint point);

/**
 * Returns the unit vector of `point`.
 *
 * @param point The specified point.
 */
CGPoint CGPointNormalize(CGPoint point);

/**
 * Returns a projected point in the specified direction.
 *
 * @param point The point to project.
 * @param direction A vector to project onto.
 */
CGPoint CGPointProject(CGPoint point, CGPoint direction);

/**
 * Returns the angle of a vector.
 *
 * @param point The specified point.
 */
CGFloat CGPointAngleInDegrees(CGPoint point);

/**
 *  Projects a point along a specified angle.
 *
 *  @param point The point to project.
 *  @param angleInDegrees An angle specified in degrees.
 */
CGPoint CGPointProjectAlongAngle(CGPoint point, CGFloat angleInDegrees);

/**
 * Add `p1` and `p2`.
 *
 * @param p1 The point to which to add.
 * @param p2 The point to add.
 */
CGPoint CGPointAdd(CGPoint p1, CGPoint p2);

/**
 * Subtracts `p2` from `p1`.
 *
 * @param p1 The point from which to subtract.
 * @param p2 The point to subtract.
 */
CGPoint CGPointSubtract(CGPoint p1, CGPoint p2);
