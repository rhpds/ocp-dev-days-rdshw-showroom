// Showroom v1.4.2 injects user_data into the first content source (English).
// Language versions share that environment, but retain their own attributes.
module.exports.register = function () {
  this.once('contentClassified', ({ contentCatalog }) => {
    for (const component of contentCatalog.getComponents()) {
      const english = component.versions.find(({ version }) => version === 'en')
      if (!english?.asciidoc?.attributes) continue
      for (const translated of component.versions) {
        if (translated === english) continue
        // Antora can share these config objects with the site or other versions.
        // Allocate both objects instead of mutating them, so inherited attributes
        // only affect this language version.
        translated.asciidoc = {
          ...translated.asciidoc,
          attributes: {
            ...english.asciidoc.attributes,
            ...translated.asciidoc?.attributes,
          },
        }
      }
    }
  })
}
