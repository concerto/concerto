import { describe, it, expect } from 'vitest'
import { splitFieldStyle } from '~/utils/splitFieldStyle.js'

describe('splitFieldStyle', () => {
  describe('edge cases', () => {
    it('returns empty strings for empty input', () => {
      expect(splitFieldStyle('')).toEqual({ textStyle: '', boxStyle: '' });
    });

    it('returns empty strings for undefined input', () => {
      expect(splitFieldStyle(undefined)).toEqual({ textStyle: '', boxStyle: '' });
    });

    it('returns empty strings for null input', () => {
      expect(splitFieldStyle(null)).toEqual({ textStyle: '', boxStyle: '' });
    });

    it('skips malformed entries without a colon', () => {
      expect(splitFieldStyle('not-a-style')).toEqual({ textStyle: '', boxStyle: '' });
    });

    it('handles extra whitespace and trailing semicolons', () => {
      const result = splitFieldStyle('  color : #fff ;  ;  ');
      expect(result).toEqual({ textStyle: 'color : #fff;', boxStyle: '' });
    });
  });

  describe('text-only styles', () => {
    it('keeps color in textStyle', () => {
      const result = splitFieldStyle('color:#000;');
      expect(result.textStyle).toBe('color:#000;');
      expect(result.boxStyle).toBe('');
    });

    it('keeps font properties in textStyle', () => {
      const result = splitFieldStyle('font-family:Arial; font-weight:bold; font-size:1em;');
      expect(result.textStyle).toBe('font-family:Arial; font-weight:bold; font-size:1em;');
      expect(result.boxStyle).toBe('');
    });

    it('keeps letter-spacing and text properties in textStyle', () => {
      const result = splitFieldStyle('letter-spacing:.12em; text-align:center;');
      expect(result.textStyle).toBe('letter-spacing:.12em; text-align:center;');
      expect(result.boxStyle).toBe('');
    });

    it('keeps unknown properties in textStyle for backward compatibility', () => {
      const result = splitFieldStyle('custom-prop:value;');
      expect(result.textStyle).toBe('custom-prop:value;');
      expect(result.boxStyle).toBe('');
    });
  });

  describe('box-model styles', () => {
    it('puts border in boxStyle', () => {
      const result = splitFieldStyle('border:1px solid #ccc;');
      expect(result.textStyle).toBe('');
      expect(result.boxStyle).toBe('border:1px solid #ccc;');
    });

    it('puts border variants in boxStyle', () => {
      const result = splitFieldStyle('border-top:1px solid red; border-radius:4px; border-color:#fff;');
      expect(result.textStyle).toBe('');
      expect(result.boxStyle).toBe('border-top:1px solid red; border-radius:4px; border-color:#fff;');
    });

    it('keeps background properties in textStyle', () => {
      const result = splitFieldStyle('background-color:#f00; background:blue;');
      expect(result.textStyle).toBe('background-color:#f00; background:blue;');
      expect(result.boxStyle).toBe('');
    });

    it('puts padding in boxStyle', () => {
      const result = splitFieldStyle('padding:10px; padding-left:5px;');
      expect(result.textStyle).toBe('');
      expect(result.boxStyle).toBe('padding:10px; padding-left:5px;');
    });

    it('puts box-shadow in boxStyle', () => {
      const result = splitFieldStyle('box-shadow:0 2px 4px rgba(0,0,0,0.1);');
      expect(result.textStyle).toBe('');
      expect(result.boxStyle).toBe('box-shadow:0 2px 4px rgba(0,0,0,0.1);');
    });

    it('puts outline in boxStyle', () => {
      const result = splitFieldStyle('outline:2px solid blue; outline-offset:3px;');
      expect(result.textStyle).toBe('');
      expect(result.boxStyle).toBe('outline:2px solid blue; outline-offset:3px;');
    });
  });

  describe('mixed styles', () => {
    it('correctly splits mixed text and box-model styles', () => {
      const result = splitFieldStyle('color:#000; border:1px solid #ccc; font-family:Arial;');
      expect(result.textStyle).toBe('color:#000; font-family:Arial;');
      expect(result.boxStyle).toBe('border:1px solid #ccc;');
    });
  });

  describe('values with colons', () => {
    it('preserves values containing colons', () => {
      const result = splitFieldStyle('background-image:url(http://example.com/img.png);');
      expect(result.textStyle).toBe('background-image:url(http://example.com/img.png);');
    });
  });

  describe('real database styles', () => {
    it('splits Ruby Main position style', () => {
      const result = splitFieldStyle('font-family:Frobisher, Arial, sans-serif; color:#000; border:solid 1px #ccc;');
      expect(result.textStyle).toBe('font-family:Frobisher, Arial, sans-serif; color:#000;');
      expect(result.boxStyle).toBe('border:solid 1px #ccc;');
    });

    it('puts Waves Main border entirely in boxStyle', () => {
      const result = splitFieldStyle('border:solid 2px #663333;');
      expect(result.textStyle).toBe('');
      expect(result.boxStyle).toBe('border:solid 2px #663333;');
    });

    it('keeps BlueSwoosh Ticker style entirely in textStyle', () => {
      const result = splitFieldStyle('color:#FFF; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important;');
      expect(result.textStyle).toBe('color:#FFF; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important;');
      expect(result.boxStyle).toBe('');
    });

    it('keeps BlueSwoosh Time style entirely in textStyle', () => {
      const result = splitFieldStyle('color:#ccc; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important; letter-spacing:.12em !important;');
      expect(result.textStyle).toBe('color:#ccc; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important; letter-spacing:.12em !important;');
      expect(result.boxStyle).toBe('');
    });
  });
});
